module Screens.RideRequestScreen.Controller where

import Prelude
import Screens.RideRequestScreen.ScreenData
import Data.Array (find, elem, filter, mapWithIndex, length, nubByEq)
import PrestoDOM (Eval, continue, exit, continueWithCmd, update , ScrollState(..),updateAndExit)
import PrestoDOM.Types.Core (class Loggable, defaultPerformLog)
import Data.Array ((!!), union, length, unionBy, any, filter) as Array
import Prim.Boolean (False)
import Screens (ScreenName(..), getScreen)
import Data.Function.Uncurried (runFn1)
import Engineering.Helpers.Commons as EHC
import JBridge as JBridge
import Debug
import PrestoDOM.Types.Core (class Loggable, toPropValue)
import Screens.Types (AnimationState(..), RideRequestCardState, ItemState, RideCardItemState)
import Components.RideRequestCard.Controller as RideRequestCardActionController
import Services.API
import Engineering.Helpers.Commons (convertUTCtoISC)
import Data.Maybe
import Services.API
import Common.Types.App as CTA
import Resource.Constants
import JBridge (fromMetersToKm, differenceBetweenTwoUTC)
import Data.Array (mapWithIndex, (!!), length, null)
import Data.Function.Uncurried (runFn2)
import Helpers.Utils as HU
import Engineering.Helpers.Commons
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), split, length, take, drop, joinWith, trim)
import Data.Int (fromString)
import Styles.Colors as Color
import Data.Int as Int
import Prelude (class Eq, class Show, Unit, identity, unit, ($), (/=), (==), (<>), (<<<))
import Screens.Types as ST
import Data.Array as DA
import Language.Types (STR(..)) as LType
import Language.Strings (getString)



instance showAction :: Show Action where
  show _ = ""

instance loggableAction :: Loggable Action where
  performLog = defaultPerformLog

data ScreenOutput
  = GoBack RideRequestScreenState
  | LoaderOutput RideRequestScreenState
  | RefreshScreen RideRequestScreenState
  | GoToRideSummary RideRequestScreenState
  | FcmNotifications String RideRequestScreenState

data Action
  = BackPressed
  | SelectDay Int
  | NoAction
  | RideRequestCardActionController RideRequestCardActionController.Action
  | PastRideApiAC ScheduledBookingListResponse String
  | GetRideList ScheduledBookingListResponse String
  | Refresh
  | ShowMap String String String
  | AfterRender
  | RideTypeSelected (Maybe (CTA.TripCategoryTag)) Int
  | FilterSelected
  | OnClickToime Int
  | Scroll String
  | ScrollStateChanged ScrollState
  | Loader
  | OnFadeComplete String
  | Notification String


eval :: Action -> RideRequestScreenState -> Eval Action ScreenOutput RideRequestScreenState
eval BackPressed state = exit $ GoBack state

eval (SelectDay index) state = do
  let
    updatedItem = map (\item ->  item { isSelected = item.index == index  }) state.data.dayArray

    newState = state { data { dayArray = updatedItem , activeDayIndex = index , shimmerLoader  = ST.AnimatedIn} }
  continueWithCmd newState [pure $ FilterSelected]


eval NoAction state = continue state

eval Refresh state = 
  let newState = state {data {refreshLoader = true , shimmerLoader = ST.AnimatingIn}} 
  in updateAndExit newState $ RefreshScreen newState

eval Loader state = updateAndExit state{data{shimmerLoader = AnimatedIn,loaderButtonVisibility = true}} $ LoaderOutput state


eval AfterRender state = continue state

eval (PastRideApiAC (ScheduledBookingListResponse resp) _) state = do 

  let (ScheduledBookingListResponse oldBookingsResp) = state.data.resp
      updatedBookings = nubByEq (\(ScheduleBooking a) (ScheduleBooking b) -> let
                                (BookingAPIEntity response1) = a.bookingDetails
                                (BookingAPIEntity response2) = b.bookingDetails
                                in
                                response1.id == response2.id) $ DA.union oldBookingsResp.bookings resp.bookings
      updatedBookingResp = ScheduledBookingListResponse { bookings : updatedBookings}
  continueWithCmd state { data { resp = updatedBookingResp, loadMoreDisabled =  false , refreshLoader  = false ,shimmerLoader = AnimatedIn }, props {receivedResponse = true } } [ pure $ FilterSelected ]


eval (RideTypeSelected rideType idx  )state = continueWithCmd state {data { activeRideIndex = idx , shimmerLoader = ST.AnimatedIn} } [pure $ FilterSelected]

eval FilterSelected state = do
  let
    (ScheduledBookingListResponse resp) = state.data.resp
    rideType = maybe Nothing (\item -> item.rideType) (state.data.pillViewArray !! state.data.activeRideIndex)

    filteredList =
      filter
        ( \(ScheduleBooking trip) ->
            let
              (BookingAPIEntity booking) = trip.bookingDetails
              (CTA.TripCategory tripCategory) = booking.tripCategory
            in
              rideType == Nothing || Just tripCategory.tag == rideType
        )
        resp.bookings

    filleteredBasedOntime =
      filter
        ( \(ScheduleBooking trip) ->
        let
           (BookingAPIEntity booking)  = trip.bookingDetails
           now = (EHC.convertUTCtoISC (EHC.getCurrentUTC "") "YYYY-MM-DD") 
           ride_date  = (EHC.convertUTCtoISC booking.startTime "YYYY-MM-DD") 

          in 
            
           if state.data.activeDayIndex == 0 then (getFutureDate now 1) /= ride_date else (getFutureDate now 1) == ride_date
        )
        filteredList
    shimmerLoader =  ST.AnimatedOut
    updatedItem = map (\item -> item { isSelected = (item.index == state.data.activeRideIndex) }) state.data.pillViewArray
  continue state { data { filteredArr = filleteredBasedOntime, pillViewArray = updatedItem, shimmerLoader = shimmerLoader } }



eval (Scroll value) state = do
  let
    firstIndex = fromMaybe 0 (fromString (fromMaybe "0" ((split (Pattern ",") (value)) Array.!! 0)))
  let
    visibleItems = fromMaybe 0 (fromString (fromMaybe "0" ((split (Pattern ",") (value)) Array.!! 1)))
  let
    totalItems = fromMaybe 0 (fromString (fromMaybe "0" ((split (Pattern ",") (value)) Array.!! 2)))
  let
    canScrollUp = fromMaybe true (strToBool (fromMaybe "true" ((split (Pattern ",") (value)) Array.!! 3)))
  let
    enableScroll = (firstIndex /= 0)
  let
    loaderButtonVisibility = if (totalItems == (firstIndex + visibleItems) && totalItems /= 0 && totalItems /= visibleItems) then true else false
  continue state {data { scrollEnable = enableScroll , loaderButtonVisibility = loaderButtonVisibility } }


eval (ScrollStateChanged scrollState) state = case scrollState of
           SCROLL_STATE_FLING -> continue state{data{scrollEnable = true}}
           _ -> continue state

eval (RideRequestCardActionController (RideRequestCardActionController.Select index )) state = do 
                                                                                                let newArr = (state.data.filteredArr) !! index
                                                                                                case newArr of 
                                                                                                  Nothing -> continue state
                                                                                                  Just (ScheduleBooking cardData) -> do 
                                                                                                                                        let (BookingAPIEntity booking) = cardData.bookingDetails
                                                                                                                                            now = EHC.getCurrentUTC ""
                                                                                                                                            diff = runFn2 differenceBetweenTwoUTC booking.startTime now 
                                                                                                                                        if diff < 0 then continue state else exit $ GoToRideSummary state{data{currCard = cardData.bookingDetails, fareDetails = cardData.fareDetails}}

eval (OnFadeComplete _ ) state = do      
  if not state.props.receivedResponse 
    then do
      continue state
    else do
      continue state {data{
            shimmerLoader = case state.data.shimmerLoader of
                              AnimatedIn ->AnimatedOut
                              AnimatingOut -> AnimatedOut
                              a -> a
              }
  }

eval (Notification notificationType) state = do
    if (HU.checkNotificationType notificationType ST.DRIVER_ASSIGNMENT ) then do
      exit $ FcmNotifications notificationType state
    else continue state

eval _ state = update state



myRideListTransformerProp :: Array ScheduleBooking -> Array RideCardItemState
myRideListTransformerProp listres =
  let resp = map ( \(ScheduleBooking ride) ->
        let
          (BookingAPIEntity booking)  = ride.bookingDetails
          time = (convertUTCtoISC booking.createdAt "h:mm A")

          totalAmount = Int.ceil ( booking.estimatedFare )

          estimatedDuration = show $ fromMaybe 0 booking.estimatedDuration/3600

          startTime = (convertUTCtoISC booking.startTime "h:mm A")

          id = booking.id

          date = (convertUTCtoISC booking.createdAt "DD/MM/YYYY")

          distance = fromMetersToKm (fromMaybe 1 booking.estimatedDistance)

          (Location fromLocation) = booking.fromLocation

          srcLat = fromLocation.lat

          srcLong = fromLocation.lon

          (Location toLocation) = 
            fromMaybe
              ( Location
                  { address:
                      LocationAddress
                        { area: Nothing
                        , areaCode: Nothing
                        , building: Nothing
                        , city: Nothing
                        , country: Nothing
                        , state: Nothing
                        , street: Nothing
                        , fullAddress : Nothing
                        , door : Nothing
                        }
                  , createdAt: ""
                  , id: ""
                  , lat: 0.00
                  , lon: 0.00
                  , updatedAt: ""
                  }
              )
              booking.toLocation

          desLat = toLocation.lat

          desLong = toLocation.lon

          (CTA.TripCategory tripCategory) = booking.tripCategory

          rideType = tripCategory.tag
          
          visible = if isJust booking.toLocation then "visible" else "gone"


          pillColor  = case rideType of
               CTA.Rental -> Color.blueGreen
               CTA.InterCity -> Color.blue800 
               _ -> Color.green700
          
          visiblePill = if rideType == CTA.OneWay then "gone" else "visible"
          

          vehicleType = booking.vehicleServiceTierName 

          image = case booking.vehicleServiceTier of
            AUTO_RICKSHAW -> "ny_ic_auto_side_view"
            SEDAN_TIER -> "ny_ic_sedan"
            COMFY -> "ny_ic_sedan_ac"
            ECO -> "ny_ic_ac_mini"
            PREMIUM -> "ny_ic_sedan"
            SUV_TIER -> "ny_ic_suv_ac"
            HATCHBACK_TIER -> "ic_hatchback_ac"
            TAXI -> "ny_ic_non_ac"
            TAXI_PLUS -> "ny_ic_sedan_ac"
            _ -> "ny_ic_ac_mini"

          
          now   = EHC.getCurrentUTC ""
          diff  = runFn2 differenceBetweenTwoUTC booking.startTime now 
          overlayVisiblity  = if  diff< 0 then "visible" else "gone"
          imageType = case rideType of
                CTA.Rental -> "ny_ic_clock_unfilled"
                _ -> "ny_ic_ride_rental_vector"
          

          
        in
          { date: toPropValue date
          , time: toPropValue startTime
          , distance: toPropValue distance
          , source: toPropValue (decodeShortAddress (transformer booking.fromLocation))
          , destination: toPropValue $ (decodeShortAddress (transformer (Location toLocation)))
          , totalAmount: toPropValue $ ("₹ " <> show totalAmount)
          , cardVisibility: toPropValue "visible"
          , shimmerVisibility: toPropValue "gone"
          , carImage: toPropValue $ totalAmount
          , rideType: toPropValue $ if booking.roundTrip == Just true then getString LType.INTERCITY_RETURN else  (show rideType)
          , vehicleType: toPropValue $  vehicleType
          , srcLat: toPropValue $ show srcLat
          , srcLong: toPropValue $ show srcLong
          , desLat: toPropValue $ show desLat
          , desLong: toPropValue desLong
          , id: toPropValue id
          , image: toPropValue image
          , visible: toPropValue visible
          , pillColor : (toPropValue pillColor)
          , overlayVisiblity : toPropValue overlayVisiblity
          , visiblePill : (toPropValue visiblePill)
          , cornerRadius :  toPropValue  "32.0"
          , imageType : toPropValue $ imageType
          , estimatedDuration : toPropValue (estimatedDuration <> " "<>"hr")
          }
        )
        listres
    in resp 
transformer :: Location -> LocationInfo
transformer (Location loc) =
  let
    (LocationAddress addr) = (loc.address)
  in
    LocationInfo
      { area: addr.area
      , state: addr.state
      , country: addr.country
      , building: addr.building
      , door: Nothing
      , street: addr.street
      , lat: loc.lat
      , city: addr.city
      , areaCode: addr.areaCode
      , lon: loc.lon
      }