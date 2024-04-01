{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module Storage.Beam.Ride where

import qualified Database.Beam as B
import qualified Domain.Types.Ride
import qualified Domain.Types.VehicleVariant
import Kernel.External.Encryption
import Kernel.Prelude
import qualified Kernel.Prelude
import qualified Kernel.Types.Common
import Tools.Beam.UtilsTH

data RideT f = RideT
  { allowedEditLocationAttempts :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Int),
    bookingId :: B.C f Kernel.Prelude.Text,
    bppRideId :: B.C f Kernel.Prelude.Text,
    chargeableDistance :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.HighPrecMeters),
    clientId :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    createdAt :: B.C f Kernel.Prelude.UTCTime,
    driverArrivalTime :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.UTCTime),
    driverImage :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    driverMobileCountryCode :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    driverMobileNumber :: B.C f Kernel.Prelude.Text,
    driverName :: B.C f Kernel.Prelude.Text,
    driverRating :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.Centesimal),
    driverRegisteredAt :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.UTCTime),
    endOdometerReading :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.Centesimal),
    endOtp :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    currency :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.Currency),
    fare :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.HighPrecMoney),
    id :: B.C f Kernel.Prelude.Text,
    isFreeRide :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Bool),
    merchantId :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    merchantOperatingCityId :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    otp :: B.C f Kernel.Prelude.Text,
    rideEndTime :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.UTCTime),
    rideRating :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Int),
    rideStartTime :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.UTCTime),
    safetyCheckStatus :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Bool),
    shortId :: B.C f Kernel.Prelude.Text,
    startOdometerReading :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.Centesimal),
    status :: B.C f Domain.Types.Ride.RideStatus,
    totalFare :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.HighPrecMoney),
    trackingUrl :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    traveledDistance :: B.C f (Kernel.Prelude.Maybe Kernel.Types.Common.HighPrecMeters),
    updatedAt :: B.C f Kernel.Prelude.UTCTime,
    vehicleColor :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    vehicleModel :: B.C f Kernel.Prelude.Text,
    vehicleNumber :: B.C f Kernel.Prelude.Text,
    vehicleVariant :: B.C f Domain.Types.VehicleVariant.VehicleVariant
  }
  deriving (Generic, B.Beamable)

instance B.Table RideT where
  data PrimaryKey RideT f = RideId (B.C f Kernel.Prelude.Text) deriving (Generic, B.Beamable)
  primaryKey = RideId . id

type Ride = RideT Identity

$(enableKVPG ''RideT ['id] [['bookingId], ['bppRideId]])

$(mkTableInstances ''RideT "ride")