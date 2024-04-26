{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module Domain.Types.BookingCancellationReason where

import qualified Domain.Types.Booking
import qualified Domain.Types.CancellationReason
import qualified Domain.Types.Merchant
import qualified Domain.Types.Person
import qualified Domain.Types.Ride
import qualified Kernel.External.Maps
import Kernel.Prelude
import qualified Kernel.Types.Common
import qualified Kernel.Types.Id
import qualified Tools.Beam.UtilsTH

data BookingCancellationReason = BookingCancellationReason
  { additionalInfo :: Kernel.Prelude.Maybe Kernel.Prelude.Text,
    bookingId :: Kernel.Types.Id.Id Domain.Types.Booking.Booking,
    driverCancellationLocation :: Kernel.Prelude.Maybe Kernel.External.Maps.LatLong,
    driverDistToPickup :: Kernel.Prelude.Maybe Kernel.Types.Common.Meters,
    driverId :: Kernel.Prelude.Maybe (Kernel.Types.Id.Id Domain.Types.Person.Person),
    merchantId :: Kernel.Prelude.Maybe (Kernel.Types.Id.Id Domain.Types.Merchant.Merchant),
    reasonCode :: Kernel.Prelude.Maybe Domain.Types.CancellationReason.CancellationReasonCode,
    rideId :: Kernel.Prelude.Maybe (Kernel.Types.Id.Id Domain.Types.Ride.Ride),
    source :: Domain.Types.BookingCancellationReason.CancellationSource,
    createdAt :: Kernel.Prelude.UTCTime,
    updatedAt :: Kernel.Prelude.UTCTime
  }
  deriving (Generic, Show, ToJSON, FromJSON, ToSchema)

data CancellationSource = ByUser | ByDriver | ByMerchant | ByAllocator | ByApplication deriving (Eq, Ord, Show, Read, Generic, ToJSON, FromJSON, ToSchema)

$(Tools.Beam.UtilsTH.mkBeamInstancesForEnumAndList (''CancellationSource))