module Components.DateTimeSelector.View where 


import Components.DateTimeSelector.Controller
import Prelude

import Common.Types.App (LazyCheck(..))
import Components.MenuButton as MenuButton
import Components.MenuButton.Controller as MenuButtonController
import Data.String (take)
import Effect (Effect)
import Font.Style (Style(..))
import Font.Style as FontStyle
import Helpers.Utils (FetchImageFrom(..), fetchImage)
import Language.Types (STR(..))
import PrestoDOM (Gravity(..), Length(..), Margin(..), layoutGravity, Orientation(..), Padding(..), PrestoDOM, Screen, Visibility(..),Accessiblity(..),accessibility,accessibilityHint, alpha, clickable, imageWithFallback, background, color, fontStyle, gravity, height, linearLayout, imageView, margin, orientation, padding, text, textSize, textView, weight, width, onClick, alpha, cornerRadius, id, visibility, stroke)
import Styles.Colors as Color
import Mobility.Prelude (noView)


view :: forall w. (Action -> Effect Unit) -> DateSelectorConfig -> PrestoDOM (Effect Unit) w
view push config =  linearLayout
    [ width config.baseWidth
    , height config.baseHeight
    , orientation config.baseOrientation
    , margin $ ( Margin 16 0 16 16)
    ]  
    [ textView $
        [ text config.titleConfig
        , color config.textColor
        , margin config.textMargin
        ] <> FontStyle.tags TypoGraphy
    , if config.returnTextViewVisibilty then returnTextView config else noView
    , if config.radioButtonViewVisibilty then radioButtonView push config else noView
    , linearLayout
        [ height config.pickerHeight
        , width config.pickerWidth
        , cornerRadius config.pickerCornerRadius
        , background config.pickerBackground
        , padding config.pickerPadding
        , stroke $ "1," <> Color.grey900
        , alpha if config.isEnabled then 1.0 else 0.5
        , onClick push $ const $ OnClick config.id
        , clickable $ config.isEnabled
        ]
        [ textView $
            [ text config.selectDateText
            , height config.dateHeight
            , color config.dateColor
            , accessibility ENABLE
            , accessibilityHint $ if not config.isEnabled then "disabled" else config.selectDateText
            , weight 1.0
            ] <> FontStyle.subHeading3 TypoGraphy 
        , imageView
            [  height $ V 22 
            , width $ V 22
            , margin $ MarginLeft 8
            , gravity RIGHT
            , imageWithFallback $ fetchImage FF_COMMON_ASSET "ny_ic_calendar" 
            ]
        ]
    ]


radioButtonView :: forall w. (Action -> Effect Unit) -> DateSelectorConfig -> PrestoDOM (Effect Unit) w
radioButtonView push config = 
    linearLayout[
        height WRAP_CONTENT,
        width MATCH_PARENT
    ][
        MenuButton.view (push <<< MenuButtonActionController) (leaveNowButtonConfig config),
        MenuButton.view (push <<< MenuButtonActionController) (leaveLaterButtonConfig config)
    ]

returnTextView :: forall w. DateSelectorConfig -> PrestoDOM (Effect Unit) w 
returnTextView config = textView $
        [   height WRAP_CONTENT,
            width MATCH_PARENT,
            text $ config.returnViewPrimaryText,
            color $ Color.black700,
            margin $ MarginBottom 8,
            accessibilityHint $ config.returnViewPrimaryText
        ] <> FontStyle.tags TypoGraphy

leaveNowButtonConfig :: forall w. DateSelectorConfig -> MenuButton.Config
leaveNowButtonConfig state  = let
    isFocussed = not state.isEnabled 
    layoutBg = if isFocussed then Color.blue600 else Color.white900
    layoutStroke = if isFocussed then ("1," <> Color.blue700) else ("1," <> Color.grey900)
    config = MenuButton.config
    menuButtonConfig' = config {
      titleConfig{
          text = state.radioButtonTextConfig.primaryText
        , gravity = CENTER_VERTICAL
        , selectedTextStyle = Body6
        , unselectedTextStyle = Body6
      }
    , accessibilityHint = (state.radioButtonTextConfig.primaryTextAccessibilityHint)
    , radioButtonConfig {
        height = V 16
        , width = V 16
        , cornerRadius = 8.0
        , buttonWidth = V 8
        , buttonHeight = V 8
        , buttonColor = Color.black900
        , margin = (MarginRight 15)
        , activeStroke = ("2," <> Color.black900)
      }
      , leftsidebutton = true
      , padding = (Padding 14 14 14 14)
      , cornerRadius = 6.0
      , height = WRAP_CONTENT
      , width = WRAP_CONTENT
      , weight = 1.0
      , margin = (Margin 0 0 4 8)
      , isSelected = isFocussed
      , layoutStroke = layoutStroke
      , layoutBg = layoutBg
      , id = "LeaveNow"
    }
    in menuButtonConfig'


leaveLaterButtonConfig :: DateSelectorConfig -> MenuButton.Config
leaveLaterButtonConfig state  = let
    isFocussed = state.isEnabled
    layoutBg = if isFocussed then Color.blue600 else Color.white900
    layoutStroke = if isFocussed then ("1," <> Color.blue700) else ("1," <> Color.grey900)
    config = MenuButton.config
    menuButtonConfig' = config {
      titleConfig{
          text = state.radioButtonTextConfig.secondaryText
        , gravity = CENTER_VERTICAL
        , selectedTextStyle = Body6
        , unselectedTextStyle = Body6
      }
    , accessibilityHint = state.radioButtonTextConfig.secondaryTextAccessibilityHint
    , radioButtonConfig {
        height = V 16
        , width = V 16
        , cornerRadius = 8.0
        , buttonWidth = V 8
        , buttonHeight = V 8
        , buttonColor = Color.black900
        , margin = (MarginRight 15)
        , activeStroke = ("2," <> Color.black900)
      }
      , leftsidebutton = true
      , padding = (Padding 14 14 14 14)
      , margin = (Margin 4 0 0 8)
      , cornerRadius = 6.0
      , height = WRAP_CONTENT
      , width = WRAP_CONTENT
      , weight = 1.0
      , isSelected = isFocussed
      , layoutStroke = layoutStroke
      , layoutBg = layoutBg
      , id = "LeaveLater"
    }
    in menuButtonConfig'