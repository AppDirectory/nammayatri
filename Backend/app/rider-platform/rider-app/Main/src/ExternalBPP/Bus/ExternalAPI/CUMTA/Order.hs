module ExternalBPP.Bus.ExternalAPI.CUMTA.Order where

import API.Types.UI.FRFSTicketService
import Crypto.Cipher.TripleDES
import Crypto.Cipher.Types
import Crypto.Error (CryptoFailable (..))
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base64 as Base64
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Time as Time
import Data.Time.Format
import qualified Data.UUID as UU
import Domain.Types.FRFSTicketBooking
import Domain.Types.IntegratedBPPConfig
import ExternalBPP.Bus.ExternalAPI.Types
import Kernel.Beam.Functions as B
import Kernel.Prelude
import Kernel.Storage.Esqueleto.Config
import Kernel.Tools.Metrics.CoreMetrics (CoreMetrics)
import Kernel.Types.Base64
import Kernel.Utils.Common
import qualified Storage.Queries.Route as QRoute
import qualified Storage.Queries.RouteStopMapping as QRouteStopMapping
import qualified Storage.Queries.Station as QStation
import Tools.Error

createOrder :: (CoreMetrics m, MonadTime m, MonadFlow m, CacheFlow m r, EsqDBFlow m r, EncFlow m r) => CUMTAConfig -> Seconds -> FRFSTicketBooking -> m ProviderOrder
createOrder config qrTtl booking = do
  when (isJust booking.bppOrderId) $ throwError (InternalError $ "Order Already Created for Booking : " <> booking.id.getId)
  bookingUUID <- UU.fromText booking.id.getId & fromMaybeM (InternalError "Booking Id not being able to parse into UUID")
  let orderId = show (fromIntegral ((\(a, b, c, d) -> a + b + c + d) (UU.toWords bookingUUID)) :: Integer) -- This should be max 20 characters UUID (Using Transaction UUID)
      mbRouteStations :: Maybe [FRFSRouteStationsAPI] = decodeFromText =<< booking.routeStationsJson
  routeStations <- mbRouteStations & fromMaybeM (InternalError "Route Stations Not Found.")
  tickets <- mapM (getTicketDetail config qrTtl booking) routeStations
  return ProviderOrder {..}

-- CUMTA Encrypted QR code generation
-- 1. From Route Stop Srl No : 1258001
-- 2. To Route Stop Srl No : 1258016
-- 3. No Adult : 1
-- 4. No child : 1
-- 5. Bus Type Id : 4
-- 6. Exp Date time - Expiry date of QR code  dd-MM-yyyy HH:mm:ss  : 10-12-2021 14:19:50
-- 7. Transaction unique no (max 20 chars) : 123456712  for reconciliation
-- 8. Ticket Amount :  25
-- 9. Agent ID : 5185
-- 10. UDF1
-- 11. UDF2
-- 12. UDF3
-- 13. UDF4
-- 14. MB_TKT_ID = 130
-- 15. UDF5
-- 16. UDF6
-- {tt: [{t: "37001,37017,1,0,5,10-10-2024 19:04:54,2185755416,13,5185,,,,,130,,,"}]}
getTicketDetail :: (MonadTime m, MonadFlow m, CacheFlow m r, EsqDBFlow m r) => CUMTAConfig -> Seconds -> FRFSTicketBooking -> FRFSRouteStationsAPI -> m ProviderTicket
getTicketDetail config qrTtl booking routeStation = do
  busTypeId <- routeStation.vehicleServiceTier <&> (.providerCode) & fromMaybeM (InternalError "Bus Provider Code Not Found.")
  when (null routeStation.stations) $ throwError (InternalError "Empty Stations")
  let startStation = head routeStation.stations
      endStation = last routeStation.stations
  fromStation <- B.runInReplica $ QStation.findByStationCode startStation.code >>= fromMaybeM (StationNotFound startStation.code)
  toStation <- B.runInReplica $ QStation.findByStationCode endStation.code >>= fromMaybeM (StationNotFound endStation.code)
  route <- B.runInReplica $ QRoute.findByRouteCode routeStation.code >>= fromMaybeM (RouteNotFound routeStation.code)
  fromRoute <- B.runInReplica $ QRouteStopMapping.findByRouteCodeAndStopCode route.code fromStation.code >>= fromMaybeM (RouteMappingDoesNotExist route.code fromStation.code)
  toRoute <- B.runInReplica $ QRouteStopMapping.findByRouteCodeAndStopCode route.code toStation.code >>= fromMaybeM (RouteMappingDoesNotExist route.code toStation.code)
  qrValidity <- addUTCTime (secondsToNominalDiffTime qrTtl) <$> getCurrentTime
  ticketNumber <- do
    id <- generateGUID
    uuid <- UU.fromText id & fromMaybeM (InternalError "Not being able to parse into UUID")
    return $ show (fromIntegral ((\(a, b, c, d) -> a + b + c + d) (UU.toWords uuid)) :: Int)
  let amount = Money $ round routeStation.priceWithCurrency.amount
  let adultQuantity = booking.quantity
      childQuantity :: Int = 0
      qrValidityIST = addUTCTime (secondsToNominalDiffTime 19800) qrValidity
      ticket = "{tt: [{t: \"" <> fromRoute.providerCode <> "," <> toRoute.providerCode <> "," <> show adultQuantity <> "," <> show childQuantity <> "," <> busTypeId <> "," <> formatUtcTime qrValidityIST <> "," <> ticketNumber <> "," <> show amount <> ",,,,," <> ticketNumber <> ",,,\"}]}"
  qrData <- generateQR config ticket
  return $
    ProviderTicket
      { ticketNumber,
        qrData,
        qrStatus = "UNCLAIMED",
        qrValidity
      }
  where
    formatUtcTime :: UTCTime -> Text
    formatUtcTime utcTime = T.pack $ formatTime Time.defaultTimeLocale "%d-%m-%Y %H:%M:%S" utcTime

generateQR :: (MonadTime m, MonadFlow m, CacheFlow m r, EsqDBFlow m r) => CUMTAConfig -> Text -> m Text
generateQR config qrData = do
  let cipherKey = config.cipherKey
  encryptedQR <- encryptDES cipherKey qrData & fromEitherM (\err -> InternalError $ "Failed to encrypt: " <> show err)
  return encryptedQR
  where
    pad :: Int -> BS.ByteString -> BS.ByteString
    pad blockSize' bs =
      let padLen = blockSize' - BS.length bs `mod` blockSize'
          padding = BS.replicate padLen (fromIntegral padLen)
       in BS.append bs padding

    encryptDES :: Base64 -> Text -> Either String Text
    encryptDES (Base64 cipherKey) plainText = do
      let cipherEither = cipherInit cipherKey :: CryptoFailable DES_EDE3
      case cipherEither of
        CryptoPassed cipher ->
          let paddedPlainText = pad (blockSize cipher) (TE.encodeUtf8 plainText)
           in Right $ TE.decodeUtf8 $ Base64.encode $ ecbEncrypt cipher paddedPlainText
        CryptoFailed err -> Left $ show err
