module Screens.RideRequestScreen.Handler where
import Types.App 
import Engineering.Helpers.BackTrack (getState, liftFlowBT)
import Prelude
import Control.Monad.Except.Trans (lift)
import PrestoDOM.Core.Types.Language.Flow (runScreen)
import Screens.RideRequestScreen.View as RideRequestScreen
import Types.ModifyScreenState (modifyScreenState)
import Control.Transformers.Back.Trans (BackT(..), FailBack(..)) as App
import Screens.RideRequestScreen.Controller (ScreenOutput(..), Action(..))
import Screens.RideRequestScreen.View
import Components.RideRequestCard.View as RideRequestCard
import Engineering.Helpers.Commons (liftFlow)
import PrestoDOM.Core (getPushFn)
import PrestoDOM
import Data.Maybe (Maybe(..))
import PrestoDOM.List as PrestoList
import Presto.Core.Types.Language.Flow (getLogFields, setLogField)
import Screens.RideRequestScreen.ScreenData
import Debug

rideRequestScreen :: FlowBT String RIDE_REQUEST_SCREEN_OUTPUT
rideRequestScreen = do
  (GlobalState state) <- getState
  push <- liftFlowBT $ getPushFn Nothing "RideRequestScreen"
  listItemm <- lift $ lift $ PrestoList.preComputeListItem $ RideRequestCard.view (push <<< RideRequestCardActionController) 
  act <- lift $ lift $ runScreen $ RideRequestScreen.screen state.rideRequestScreen listItemm
  case act of
    GoBack updatedState  -> do 
      modifyScreenState $ RideRequestScreenStateType (\_ -> updatedState)
      App.BackT $ App.BackPoint <$> pure (GOTO_HOME updatedState  )
      
    RefreshScreen state -> do 
      modifyScreenState $ RideRequestScreenStateType (\_ → state) 
      App.BackT $ App.NoBack <$> pure ( RIDE_REQUEST_REFRESH_SCREEN  state)

    LoaderOutput updatedState -> do
      modifyScreenState $ RideRequestScreenStateType (\_ → updatedState) 
      App.BackT $ App.BackPoint <$> (pure $ LOADER__OUTPUT updatedState)

    GoToRideSummary updatedState -> do
      modifyScreenState $ RideRequestScreenStateType (\_ -> updatedState)
      App.BackT $ App.BackPoint <$> (pure $ GOTO_RIDE_SUMMARY updatedState)

    FcmNotifications notificationType screenState -> do 
      modifyScreenState $ RideRequestScreenStateType (\_ → screenState)
      App.BackT $ App.BackPoint <$> (pure $ NOTIFICATION_TYPE notificationType screenState)