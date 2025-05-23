import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @pageTitleNotificationDetail.
  ///
  /// In en, this message translates to:
  /// **'Notification Details'**
  String get pageTitleNotificationDetail;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @deliveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivered: {date}'**
  String deliveredLabel(Object date);

  /// No description provided for @seenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenLabel;

  /// No description provided for @unreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unreadLabel;

  /// No description provided for @relevanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get relevanceLabel;

  /// No description provided for @pageTitleNotificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get pageTitleNotificationHistory;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLabel(Object error);

  /// No description provided for @pageTitleCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get pageTitleCommunity;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Create a new one!'**
  String get noPosts;

  /// No description provided for @pageTitleProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get pageTitleProfile;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAmharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get languageAmharic;

  /// No description provided for @viewNotification.
  ///
  /// In en, this message translates to:
  /// **'View Notification'**
  String get viewNotification;

  /// No description provided for @pageTitleHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pageTitleHome;

  /// No description provided for @pageTitleHealthMetrics.
  ///
  /// In en, this message translates to:
  /// **'Health Metrics'**
  String get pageTitleHealthMetrics;

  /// No description provided for @pageTitleEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get pageTitleEducation;

  /// No description provided for @pageTitleFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get pageTitleFavorites;

  /// No description provided for @pageTitleWeeklyTip.
  ///
  /// In en, this message translates to:
  /// **'Weekly Tip'**
  String get pageTitleWeeklyTip;

  /// No description provided for @pageTitleJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get pageTitleJournal;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String greeting(String name);

  /// No description provided for @pregnancyJourney.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Journey'**
  String get pregnancyJourney;

  /// No description provided for @weeksLabel.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeksLabel;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @weeklyTips.
  ///
  /// In en, this message translates to:
  /// **'Weekly Tips'**
  String get weeklyTips;

  /// No description provided for @noTipsYet.
  ///
  /// In en, this message translates to:
  /// **'No tips yet—add some!'**
  String get noTipsYet;

  /// No description provided for @exploreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Explore Features'**
  String get exploreFeatures;

  /// No description provided for @featureCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get featureCalendar;

  /// No description provided for @featureCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan appointments'**
  String get featureCalendarDescription;

  /// No description provided for @featureHealthMetrics.
  ///
  /// In en, this message translates to:
  /// **'Health Metrics'**
  String get featureHealthMetrics;

  /// No description provided for @featureHealthMetricsDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your health'**
  String get featureHealthMetricsDescription;

  /// No description provided for @featureJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get featureJournal;

  /// No description provided for @featureJournalDescription.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts'**
  String get featureJournalDescription;

  /// No description provided for @featureNameSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Name Suggestion'**
  String get featureNameSuggestion;

  /// No description provided for @featureNameSuggestionDescription.
  ///
  /// In en, this message translates to:
  /// **'Find baby names'**
  String get featureNameSuggestionDescription;

  /// No description provided for @noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get noUserLoggedIn;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String failedToLoadProfile(Object error);

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String weekLabel(Object week);

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// No description provided for @pageTitleHealthArticle.
  ///
  /// In en, this message translates to:
  /// **'Health Article'**
  String get pageTitleHealthArticle;

  /// No description provided for @noDiaryEntries.
  ///
  /// In en, this message translates to:
  /// **'No diary entries yet'**
  String get noDiaryEntries;

  /// No description provided for @errorLoadingEntries.
  ///
  /// In en, this message translates to:
  /// **'Error loading entries: {error}'**
  String errorLoadingEntries(Object error);

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites!'**
  String get removedFromFavorites;

  /// No description provided for @errorUpdatingFavorite.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorite: {error}'**
  String errorUpdatingFavorite(Object error);

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No Content'**
  String get noContent;

  /// No description provided for @moreButton.
  ///
  /// In en, this message translates to:
  /// **'More >>>'**
  String get moreButton;

  /// No description provided for @lessButton.
  ///
  /// In en, this message translates to:
  /// **'Less >>>'**
  String get lessButton;

  /// No description provided for @postedAt.
  ///
  /// In en, this message translates to:
  /// **'Posted at: {date}'**
  String postedAt(Object date);

  /// No description provided for @weekLabelWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String weekLabelWithNumber(int week);

  /// No description provided for @favoriteEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Entries'**
  String get favoriteEntriesTitle;

  /// No description provided for @noFavoriteEntries.
  ///
  /// In en, this message translates to:
  /// **'No favorite entries yet'**
  String get noFavoriteEntries;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More >>>'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less >>>'**
  String get showLess;

  /// No description provided for @postedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Posted at'**
  String get postedAtLabel;

  /// No description provided for @bottomNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNavHome;

  /// No description provided for @bottomNavCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get bottomNavCommunity;

  /// No description provided for @bottomNavEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get bottomNavEducation;

  /// No description provided for @bottomNavConsult.
  ///
  /// In en, this message translates to:
  /// **'Consult'**
  String get bottomNavConsult;

  /// No description provided for @failedToLoadUserData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get failedToLoadUserData;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @consultPageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Consult Page (Coming Soon)'**
  String get consultPageComingSoon;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Label for the full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// Label for the blood pressure input field
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure (e.g., 120/80)'**
  String get bloodPressureLabel;

  /// No description provided for @selectHealthConditions.
  ///
  /// In en, this message translates to:
  /// **'Select applicable health conditions'**
  String get selectHealthConditions;

  /// No description provided for @describeHealthIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your health issue'**
  String get describeHealthIssue;

  /// Hint text for the health issue description input field
  ///
  /// In en, this message translates to:
  /// **'Describe your health background or issues here...'**
  String get healthIssueHint;

  /// No description provided for @saveProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfileButton;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(Object error);

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// No description provided for @galleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission denied'**
  String get galleryPermissionDenied;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large, please choose a smaller one'**
  String get imageTooLarge;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(Object error);

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, kg {kg} lbs {lbs} other {{unit}}}'**
  String weightUnit(String unit);

  /// No description provided for @heightUnit.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, cm {cm} ft {ft} other {{unit}}}'**
  String heightUnit(String unit);

  /// No description provided for @healthCondition.
  ///
  /// In en, this message translates to:
  /// **'{condition, select, diabetes {Diabetes} hypertension {Hypertension} asthma {Asthma} heartDisease {Heart Disease} thyroidIssues {Thyroid Issues} other {Other} other {{condition}}}'**
  String healthCondition(String condition);

  /// No description provided for @errorMarkingAsSeen.
  ///
  /// In en, this message translates to:
  /// **'Error marking as seen: {error}'**
  String errorMarkingAsSeen(Object error);

  /// No description provided for @tapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily Tip'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Health tips every 4 days'**
  String get notificationChannelDescription;

  /// No description provided for @fallbackTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip {index}'**
  String fallbackTipTitle(int index);

  /// No description provided for @fallbackTipBody.
  ///
  /// In en, this message translates to:
  /// **'Consult your doctor for advice.'**
  String get fallbackTipBody;

  /// No description provided for @relevanceLabelWithValue.
  ///
  /// In en, this message translates to:
  /// **'Relevance: {value}'**
  String relevanceLabelWithValue(String value);

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderSelectionError.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get genderSelectionError;

  /// No description provided for @enterHealthData.
  ///
  /// In en, this message translates to:
  /// **'Enter Health Data'**
  String get enterHealthData;

  /// No description provided for @bpSystolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Systolic (mmHg)'**
  String get bpSystolicLabel;

  /// No description provided for @bpDiastolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Diastolic (mmHg)'**
  String get bpDiastolicLabel;

  /// No description provided for @heartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate (BPM)'**
  String get heartRateLabel;

  /// No description provided for @bodyTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Body Temperature (°C)'**
  String get bodyTemperatureLabel;

  /// No description provided for @weightLabelKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightLabelKg;

  /// No description provided for @saveDataButton.
  ///
  /// In en, this message translates to:
  /// **'Save Data'**
  String get saveDataButton;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @healthTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Trends'**
  String get healthTrendsTitle;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @dataSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully!'**
  String get dataSavedSuccessfully;

  /// No description provided for @failedToSaveData.
  ///
  /// In en, this message translates to:
  /// **'Failed to save data. Please try again.'**
  String get failedToSaveData;

  /// No description provided for @invalidValuesError.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid values for all fields'**
  String get invalidValuesError;

  /// No description provided for @tempScaledLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C x 5)'**
  String get tempScaledLabel;

  /// No description provided for @bpLowRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your blood pressure appears low (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg). This could be due to dehydration, fatigue, or other factors. To stabilize, consider adding a small amount of salt (e.g., a pinch in your food), drinking more water throughout the day (aim for 8-10 glasses), and eating small, frequent meals. If you feel dizzy or faint often, consult a healthcare professional to rule out other issues.'**
  String bpLowRecommendation(int bpSys, int bpDia);

  /// No description provided for @bpHighRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your blood pressure is elevated (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg), which may indicate hypertension. To manage, reduce salt intake by avoiding processed foods and choosing fresh ingredients, engage in moderate exercise like brisk walking or cycling for 30 minutes most days of the week, and practice stress reduction techniques like yoga or deep breathing for 10-15 minutes daily. If this persists across multiple readings, consider seeing a doctor for a detailed evaluation.'**
  String bpHighRecommendation(int bpSys, int bpDia);

  /// No description provided for @bpNormalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your blood pressure (Systolic: {bpSys} mmHg, Diastolic: {bpDia} mmHg) is within the normal range. To maintain this, continue a balanced diet rich in fruits, vegetables, and lean proteins, and get at least 150 minutes of moderate exercise per week. Monitoring trends over time helps ensure it stays stable.'**
  String bpNormalRecommendation(int bpSys, int bpDia);

  /// No description provided for @hrLowRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate ({hr} BPM) is on the lower side. This can be normal for fit individuals, but if you\'re not highly active or feel unusually tired, it\'s worth monitoring. To boost cardiovascular health, include activities like jogging, swimming, or dancing a few times a week for 20-30 minutes. If your heart rate drops further or you experience symptoms like dizziness, consult a doctor.'**
  String hrLowRecommendation(int hr);

  /// No description provided for @hrHighRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate ({hr} BPM) is elevated, which could be due to stress, caffeine, or physical activity. To lower it, try relaxation techniques like deep breathing exercises (inhale for 4 seconds, exhale for 6 seconds) or meditation for 10-15 minutes daily. Limit stimulants like coffee or energy drinks, and ensure you\'re getting 7-9 hours of sleep. If consistently high, a medical evaluation may be needed.'**
  String hrHighRecommendation(int hr);

  /// No description provided for @hrNormalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate ({hr} BPM) is in a healthy range. To maintain this, continue a regular schedule of moderate physical activities like walking or cycling and manage stress effectively with hobbies or relaxation practices. Keep monitoring to spot any unusual changes.'**
  String hrNormalRecommendation(int hr);

  /// No description provided for @tempLowRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your body temperature ({temp}°C) is below average, which may indicate you\'re cold or your metabolism is sluggish. Keep warm by wearing layers or using a blanket, and consume warm beverages like herbal tea throughout the day. Monitor for signs of illness like fatigue or chills, and if this persists, consider consulting a doctor about a thyroid test, as low body temperature can sometimes indicate hormonal imbalances.'**
  String tempLowRecommendation(double temp);

  /// No description provided for @tempHighRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your body temperature ({temp}°C) is elevated, which may indicate a fever or overheating. Stay hydrated by drinking 8-12 glasses of water daily, rest in a cool environment, and avoid strenuous exercise until it subsides. If above 38°C or lasting more than a day, seek medical advice to rule out infections or other causes.'**
  String tempHighRecommendation(double temp);

  /// No description provided for @tempNormalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your body temperature ({temp}°C) is normal. To maintain this, dress appropriately for the weather, stay hydrated with 6-8 glasses of water daily, and avoid extreme temperature changes. Regular monitoring helps catch any variations early.'**
  String tempNormalRecommendation(double temp);

  /// No description provided for @weightLowRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your weight ({weight} kg) is on the lower side. To gain or maintain healthy weight, focus on a nutrient-dense diet with proteins like eggs, chicken, or beans, healthy fats like nuts or avocado, and complex carbs like whole grains. Aim for 3 balanced meals and 2 snacks daily, and consider light strength training exercises like small weight lifting to build muscle mass. If struggling to gain weight, consult a dietitian.'**
  String weightLowRecommendation(double weight);

  /// No description provided for @weightHighRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your weight ({weight} kg) is on the higher side. To manage, incorporate regular physical activity like walking, swimming, or yoga for 30-40 minutes most days of the week, and focus on a diet rich in vegetables, lean proteins, and whole grains while reducing sugary drinks and processed snacks. Set small, achievable goals (e.g., losing 0.5 kg per month) and track progress. A healthcare provider can offer tailored advice if needed.'**
  String weightHighRecommendation(double weight);

  /// No description provided for @weightNormalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your weight ({weight} kg) is in a healthy range. To maintain this, continue a balanced diet filled with fruits, vegetables, and lean proteins, and get at least 150 minutes of moderate exercise per week. Regular weigh-ins help ensure consistency over time.'**
  String weightNormalRecommendation(double weight);

  /// No description provided for @bpSysIncreasedRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your systolic blood pressure has increased by more than 10 mmHg from your last measurement (from {prevBpSys} to {bpSys}). This could be due to situational factors (e.g., stress or diet), but monitor closely over the next few days. Reduce salt intake, avoid caffeine before bed, and try a 10-minute relaxation exercise daily to see if it stabilizes.'**
  String bpSysIncreasedRecommendation(int prevBpSys, int bpSys);

  /// No description provided for @hrIncreasedRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate has increased by more than 15 BPM compared to your previous entry (from {prevHr} to {hr}). This might reflect temporary stress or activity, but if you haven’t been exercising, consider what’s changed—too much coffee, poor sleep, or stress? Take time for a calming activity like reading or a warm bath to unwind.'**
  String hrIncreasedRecommendation(int prevHr, int hr);

  /// No description provided for @weightIncreasedRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Your weight has increased by more than 2 kg from your last record (from {prevWeight} to {weight}). This could be water retention or diet-related. Cut back on salty or carb-heavy meals for a few days and increase your water intake to flush out excess fluids. If persistent, reassess your calorie intake and activity level.'**
  String weightIncreasedRecommendation(double prevWeight, double weight);

  /// No description provided for @allVitalsNormalRecommendation.
  ///
  /// In en, this message translates to:
  /// **'All your latest vitals (Blood Pressure: {bpSys}/{bpDia} mmHg, Heart Rate: {hr} BPM, Temperature: {temp}°C, Weight: {weight} kg) are within normal ranges. Great job! Keep up your healthy habits, including a balanced diet, regular exercise (150 minutes per week), and consistent sleep (7-9 hours per night) to stay on track.'**
  String allVitalsNormalRecommendation(int bpSys, int bpDia, int hr, double temp, double weight);

  /// No description provided for @noDataRecommendation.
  ///
  /// In en, this message translates to:
  /// **'No data available yet. Start entering your health metrics to receive personalized recommendations.'**
  String get noDataRecommendation;

  /// No description provided for @tooltipBpSys.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Sys: {value} mmHg'**
  String tooltipBpSys(int value);

  /// No description provided for @tooltipHr.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate: {value} BPM'**
  String tooltipHr(int value);

  /// No description provided for @tooltipTemp.
  ///
  /// In en, this message translates to:
  /// **'Temperature: {value}°C'**
  String tooltipTemp(double value);

  /// No description provided for @tooltipWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight: {value} kg'**
  String tooltipWeight(double value);

  /// No description provided for @boysLabel.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get boysLabel;

  /// No description provided for @femaleGender.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleGender;

  /// No description provided for @girlsLabel.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get girlsLabel;

  /// No description provided for @maleGender.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleGender;

  /// No description provided for @noNamesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No names available for {category}'**
  String noNamesAvailable(String category);

  /// No description provided for @pageTitleNameSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Baby Name Suggestion'**
  String get pageTitleNameSuggestion;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get tabChristian;

  /// No description provided for @tabMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get tabMuslim;

  /// No description provided for @addNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNoteLabel;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @errorDeletingNote.
  ///
  /// In en, this message translates to:
  /// **'Error deleting note: {error}'**
  String errorDeletingNote(Object error);

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get loginPrompt;

  /// No description provided for @noNotesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No notes match your search'**
  String get noNotesMatchSearch;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Add one!'**
  String get noNotesYet;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes by title...'**
  String get searchHint;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appointmentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Appointment Accepted'**
  String get appointmentAccepted;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment Cancelled'**
  String get appointmentCancelled;

  /// No description provided for @appointmentCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This appointment has been cancelled. The video call will end.'**
  String get appointmentCancelledMessage;

  /// No description provided for @appointmentWithDoctor.
  ///
  /// In en, this message translates to:
  /// **'Appointment with {doctorName}'**
  String appointmentWithDoctor(String doctorName);

  /// No description provided for @appointmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsLabel;

  /// No description provided for @availableDoctors.
  ///
  /// In en, this message translates to:
  /// **'Available Doctors'**
  String get availableDoctors;

  /// No description provided for @availableTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slots'**
  String get availableTimeSlots;

  /// No description provided for @beforeJoining.
  ///
  /// In en, this message translates to:
  /// **'Before Joining'**
  String get beforeJoining;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @bookAppointmentWith.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment with {fullName}'**
  String bookAppointmentWith(String fullName);

  /// No description provided for @bookNewAppointmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Book a new appointment'**
  String get bookNewAppointmentTooltip;

  /// No description provided for @bookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get bookingLabel;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended: {error}'**
  String callEnded(Object error);

  /// No description provided for @connectedToCall.
  ///
  /// In en, this message translates to:
  /// **'Connected to call'**
  String get connectedToCall;

  /// No description provided for @connectedToServer.
  ///
  /// In en, this message translates to:
  /// **'Connected to server'**
  String get connectedToServer;

  /// No description provided for @connectingToCall.
  ///
  /// In en, this message translates to:
  /// **'Connecting to call...'**
  String get connectingToCall;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkTooltip;

  /// No description provided for @couldNotCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not create user profile. Please try again.'**
  String get couldNotCreateProfile;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile: {fullName}, {speciality}'**
  String doctorProfile(String fullName, String speciality);

  /// No description provided for @doctorRating.
  ///
  /// In en, this message translates to:
  /// **'Doctor {fullName}, {speciality}, 4.5 rating'**
  String doctorRating(String fullName, String speciality);

  /// No description provided for @doctorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsLabel;

  /// Label for the email input field on the register page
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @ensureStableConnection.
  ///
  /// In en, this message translates to:
  /// **'Ensure you have a stable internet connection'**
  String get ensureStableConnection;

  /// No description provided for @errorJoiningCall.
  ///
  /// In en, this message translates to:
  /// **'Error joining call'**
  String get errorJoiningCall;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @errorSendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error sending request: {error}'**
  String errorSendingRequest(Object error);

  /// No description provided for @findQuietSpace.
  ///
  /// In en, this message translates to:
  /// **'Find a quiet, private space for your consultation'**
  String get findQuietSpace;

  /// No description provided for @haveQuestionsReady.
  ///
  /// In en, this message translates to:
  /// **'Have your questions ready for the doctor'**
  String get haveQuestionsReady;

  /// No description provided for @inCall.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get inCall;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormat;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @joinVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Join Video Call'**
  String get joinVideoCall;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get joining;

  /// No description provided for @joiningCall.
  ///
  /// In en, this message translates to:
  /// **'Joining call...'**
  String get joiningCall;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @meetingInformation.
  ///
  /// In en, this message translates to:
  /// **'Meeting Information'**
  String get meetingInformation;

  /// No description provided for @motherAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Mothers App'**
  String get motherAppTitle;

  /// No description provided for @navigateToAppointments.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Appointments page'**
  String get navigateToAppointments;

  /// No description provided for @navigateToBooking.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Booking page'**
  String get navigateToBooking;

  /// No description provided for @navigateToDoctors.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Doctors page'**
  String get navigateToDoctors;

  /// No description provided for @newMeetingLinkAvailable.
  ///
  /// In en, this message translates to:
  /// **'New meeting link available'**
  String get newMeetingLinkAvailable;

  /// No description provided for @newMeetingLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'A new video conference link is available. Would you like to join with the new link?'**
  String get newMeetingLinkMessage;

  /// No description provided for @noAcceptedAppointments.
  ///
  /// In en, this message translates to:
  /// **'No accepted appointments.\nAccepted appointments will appear here.'**
  String get noAcceptedAppointments;

  /// No description provided for @noAvailabilityFound.
  ///
  /// In en, this message translates to:
  /// **'No availability found for this doctor.'**
  String get noAvailabilityFound;

  /// No description provided for @noDateAvailable.
  ///
  /// In en, this message translates to:
  /// **'No date available'**
  String get noDateAvailable;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctors available'**
  String get noDoctorsAvailable;

  /// No description provided for @noPendingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No pending appointments.\nRequests you send will appear here.'**
  String get noPendingAppointments;

  /// No description provided for @noRejectedAppointments.
  ///
  /// In en, this message translates to:
  /// **'No rejected appointments.\nRejected appointments will appear here.'**
  String get noRejectedAppointments;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected - appointments may not be sent'**
  String get notConnected;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @okLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// No description provided for @pageTitleAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get pageTitleAppointments;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @pleaseSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a date and time'**
  String get pleaseSelectDateTime;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'4.5 (245 reviews)'**
  String get ratingLabel;

  /// No description provided for @readyToJoin.
  ///
  /// In en, this message translates to:
  /// **'Ready to join'**
  String get readyToJoin;

  /// No description provided for @refreshAppointmentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh appointments'**
  String get refreshAppointmentsTooltip;

  /// No description provided for @requestAppointment.
  ///
  /// In en, this message translates to:
  /// **'Request Appointment'**
  String get requestAppointment;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Appointment request sent! The doctor\'s response will arrive soon.'**
  String get requestSent;

  /// No description provided for @rescheduleAppointment.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Appointment'**
  String get rescheduleAppointment;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date and Time'**
  String get selectDateTime;

  /// No description provided for @specialityLabel.
  ///
  /// In en, this message translates to:
  /// **'Speciality: {speciality}'**
  String specialityLabel(String speciality);

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start Call'**
  String get startCall;

  /// No description provided for @startVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Start Video Call'**
  String get startVideoCall;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @timeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Zone: {timeZone}'**
  String timeZoneLabel(String timeZone);

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @waitingForDoctor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the doctor...'**
  String get waitingForDoctor;

  /// No description provided for @yourMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Your meeting link'**
  String get yourMeetingLink;

  /// Label for the retry button in error messages
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Hint text for the search bar in the notes section
  ///
  /// In en, this message translates to:
  /// **'Search your notes...'**
  String get searchNotesHint;

  /// Message shown when a user is not logged in
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get pleaseLogIn;

  /// Confirmation message when a note is deleted
  ///
  /// In en, this message translates to:
  /// **'Note deleted successfully'**
  String get noteDeleted;

  /// Name of the application displayed on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Adde Assistance App'**
  String get appName;

  /// Title of the dialog shown when there is no internet connection
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// Message shown in the dialog when there is no internet connection
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get noInternetMessage;

  /// Label for the female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// Label for the male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// Label for the other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// Label for the option to edit the user profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Label for the theme mode toggle (light/dark)
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// Label for the consultation fee of a doctor
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get consultationFee;

  /// Fallback text for when a doctor's name is not available
  ///
  /// In en, this message translates to:
  /// **'Unknown Name'**
  String get unknownName;

  /// Welcome message displayed on the calendar page
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Adde Assistance App!'**
  String get welcomeMessage;

  /// Instruction to test camera and microphone before joining a video call
  ///
  /// In en, this message translates to:
  /// **'Test your camera and microphone'**
  String get testCameraMic;

  /// Message indicating that the doctor will join the video call soon
  ///
  /// In en, this message translates to:
  /// **'Your doctor will join the meeting shortly'**
  String get yourDoctorWillJoin;

  /// Label for the meeting room name
  ///
  /// In en, this message translates to:
  /// **'Room: {roomName}'**
  String roomName(Object roomName);

  /// Label for the appointment status
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// Label for the scheduled date and time of the appointment
  ///
  /// In en, this message translates to:
  /// **'Scheduled for: {date}'**
  String scheduledFor(Object date);

  /// Title for the video consultation page
  ///
  /// In en, this message translates to:
  /// **'Video Consultation'**
  String get videoConsultationTitle;

  /// Message shown when an appointment is accepted and ready for video consultation
  ///
  /// In en, this message translates to:
  /// **'Your video consultation is ready to start.'**
  String get videoConsultationMessage;

  /// Label for the pending appointments tab with the number of appointments
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String tabPending(int count);

  /// Label for the accepted appointments tab with the number of appointments
  ///
  /// In en, this message translates to:
  /// **'Accepted ({count})'**
  String tabAccepted(int count);

  /// Label for the rejected appointments tab with the number of appointments
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String tabRejected(int count);

  /// Prefix for displaying the connection status
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusPrefix(String status);

  /// Label for the retry button when reconnecting
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// Error message shown when fetching user data fails
  ///
  /// In en, this message translates to:
  /// **'Error fetching user data: {error}'**
  String errorFetchingUserData(String error);

  /// Error message shown when fetching comments fails
  ///
  /// In en, this message translates to:
  /// **'Error fetching comments: {error}'**
  String errorFetchingComments(String error);

  /// Error message shown when a comment is empty or user is not logged in
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty'**
  String get commentCannotBeEmpty;

  /// Error message shown when adding a comment fails
  ///
  /// In en, this message translates to:
  /// **'Error adding comment: {error}'**
  String errorAddingComment(String error);

  /// Success message shown when a comment is deleted
  ///
  /// In en, this message translates to:
  /// **'Comment deleted successfully'**
  String get commentDeletedSuccessfully;

  /// Error message shown when deleting a comment fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting comment: {error}'**
  String errorDeletingComment(String error);

  /// Title for the post detail screen
  ///
  /// In en, this message translates to:
  /// **'Post Details'**
  String get postDetailTitle;

  /// Accessibility label for the profile avatar of the post author
  ///
  /// In en, this message translates to:
  /// **'Profile of {fullName}'**
  String profileOf(String fullName);

  /// Text displaying the number of likes for a post
  ///
  /// In en, this message translates to:
  /// **'{count} likes'**
  String likesCountText(int count);

  /// Text displaying the number of comments for a post
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCountText(int count);

  /// Accessibility label for a comment by a specific user
  ///
  /// In en, this message translates to:
  /// **'Comment by {fullName}'**
  String commentBy(String fullName);

  /// Accessibility label for the delete button of a comment by a specific user
  ///
  /// In en, this message translates to:
  /// **'Delete comment by {fullName}'**
  String deleteCommentBy(String fullName);

  /// Message shown when there are no comments on a post
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// Hint text for the comment input field
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeCommentHint;

  /// Tooltip for the send comment button
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get sendCommentTooltip;

  /// Error message shown when the chat fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load chat'**
  String get unableToLoadChat;

  /// Error message shown when the chat database table is not found
  ///
  /// In en, this message translates to:
  /// **'Chat service is currently unavailable'**
  String get chatServiceUnavailable;

  /// Error message shown when the user is not authenticated for chat
  ///
  /// In en, this message translates to:
  /// **'Please log in to access chat'**
  String get pleaseLogInChat;

  /// Error message for database-related issues
  ///
  /// In en, this message translates to:
  /// **'Database error: {message}'**
  String databaseError(String message);

  /// Error message shown when a network issue occurs
  ///
  /// In en, this message translates to:
  /// **'Network error, please check your connection'**
  String get networkError;

  /// Error message shown when sending a message fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String failedToSendMessage(String error);

  /// Message shown when there are no messages in the chat
  ///
  /// In en, this message translates to:
  /// **'Start chatting with {receiverName}'**
  String startChatting(String receiverName);

  /// Hint text for the message input field when chat is unavailable
  ///
  /// In en, this message translates to:
  /// **'Chat is currently unavailable'**
  String get chatUnavailableHint;

  /// Hint text for the message input field
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// Tooltip for the send message button
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessageTooltip;

  /// Accessibility label for a post by a specific user
  ///
  /// In en, this message translates to:
  /// **'Post by {fullName}'**
  String postBy(String fullName);

  /// Label for the edit post option in the popup menu
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// Label for the delete post option in the popup menu
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// Accessibility label for unliking a post
  ///
  /// In en, this message translates to:
  /// **'Unlike post'**
  String get unlikePost;

  /// Accessibility label for liking a post
  ///
  /// In en, this message translates to:
  /// **'Like post'**
  String get likePost;

  /// Accessibility label for commenting on a post
  ///
  /// In en, this message translates to:
  /// **'Comment on post'**
  String get commentOnPost;

  /// Label for the comment button on a post
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentPost;

  /// Error message shown when the selected image is too large
  ///
  /// In en, this message translates to:
  /// **'Image size exceeds 5MB limit'**
  String get imageSizeError;

  /// Error message shown when the post content is empty
  ///
  /// In en, this message translates to:
  /// **'Post content cannot be empty'**
  String get emptyContentError;

  /// Error message shown when user data fails to load
  ///
  /// In en, this message translates to:
  /// **'User data not loaded, please try again'**
  String get userDataNotLoaded;

  /// Error message shown when saving a post fails
  ///
  /// In en, this message translates to:
  /// **'Error saving post: {error}'**
  String errorSavingPost(String error);

  /// Tooltip for the close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// Title for the edit post screen
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostTitle;

  /// Label for the post button when creating a new post
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postButton;

  /// Label for the update button when editing a post
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// Tooltip for the remove image button
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImageTooltip;

  /// Tooltip for the add image button
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImageTooltip;

  /// Title for the create post screen
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostTitle;

  /// Error message shown when fetching user data fails
  ///
  /// In en, this message translates to:
  /// **'Error fetching user: {error}'**
  String errorFetchingUser(String error);

  /// Tooltip for the search button in the community screen
  ///
  /// In en, this message translates to:
  /// **'Search posts'**
  String get searchPosts;

  /// Accessibility label for the create post button
  ///
  /// In en, this message translates to:
  /// **'Create a new post'**
  String get createNewPost;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Label for the password input field on the register page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget password?'**
  String get forgetPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @emptyFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get emptyFieldsError;

  /// No description provided for @loginFailedError.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again'**
  String get loginFailedError;

  /// No description provided for @googleSignInCancelledError.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In cancelled'**
  String get googleSignInCancelledError;

  /// No description provided for @googleSignInFailedError.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get googleSignInFailedError;

  /// No description provided for @googleAuthFailedError.
  ///
  /// In en, this message translates to:
  /// **'Google authentication failed'**
  String get googleAuthFailedError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @invalidPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get invalidPasswordError;

  /// Welcome message displayed on the register page
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get welcomeRegister;

  /// Assistance message displayed below the welcome text on the register page
  ///
  /// In en, this message translates to:
  /// **'We Are Here, To Assist You!!!'**
  String get assistMessage;

  /// Label for the confirm password input field on the register page
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Label for the sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// Prompt for users who already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Label for the login link
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// Label for the Google Sign-Up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up with Google'**
  String get signUpWithGoogle;

  /// Error message when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordsDoNotMatchError;

  /// Error message when Google Sign-Up is cancelled
  ///
  /// In en, this message translates to:
  /// **'Google Sign-Up cancelled.'**
  String get googleSignUpCancelledError;

  /// Error message when Google Sign-Up fails
  ///
  /// In en, this message translates to:
  /// **'Google Sign-Up failed. Please try again.'**
  String get googleSignUpFailedError;

  /// Error message when Google Sign-Up fails due to missing tokens
  ///
  /// In en, this message translates to:
  /// **'Google Sign-Up Error: Missing tokens.'**
  String get googleSignUpTokenError;

  /// Error message when signup attempt fails
  ///
  /// In en, this message translates to:
  /// **'Signup failed. Please try again.'**
  String get signUpFailedError;

  /// Success message when signup is successful
  ///
  /// In en, this message translates to:
  /// **'Signup successful!'**
  String get signUpSuccess;

  /// Generic error message for signup with placeholder
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String signUpError(Object error);

  /// Title for the reset password page app bar
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Header text for the reset password page
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get resetPasswordHeader;

  /// Description prompting the user to enter their email for a reset link
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get resetPasswordDescription;

  /// Description shown after the reset email is sent
  ///
  /// In en, this message translates to:
  /// **'Check your email for the reset link'**
  String get resetLinkSentDescription;

  /// Label for the button to send the reset link
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// Label for the button after the reset email is sent
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get emailSentButton;

  /// Error message when the email field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get emptyEmailError;

  /// Success message when the reset email is sent
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String resetEmailSentSuccess(String email);

  /// Generic error message for password reset with placeholder
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String resetPasswordError(Object error);

  /// Title for the first onboarding page
  ///
  /// In en, this message translates to:
  /// **'Adey Pregnancy And Child Care App'**
  String get welcomePageTitle1;

  /// Content for the first onboarding page
  ///
  /// In en, this message translates to:
  /// **'Welcome to Adey, your trusted partner for a safe and healthy pregnancy and child care journey.'**
  String get welcomePageContent1;

  /// Content for the second onboarding page
  ///
  /// In en, this message translates to:
  /// **'Track your pregnancy and postpartum progress with tools that health status and give upgated recommedation.'**
  String get welcomePageContent2;

  /// Content for the third onboarding page
  ///
  /// In en, this message translates to:
  /// **'Access educational resources on maternal health, including articles, weekly tips, and daily notification.'**
  String get welcomePageContent3;

  /// Content for the fourth onboarding page
  ///
  /// In en, this message translates to:
  /// **'Connect with a community of users, share experiences, and receive support.'**
  String get welcomePageContent4;

  /// Content for the fifth onboarding page
  ///
  /// In en, this message translates to:
  /// **'Use our chatbot for instant responses and guidance on pregnancy and child care queries.'**
  String get welcomePageContent5;

  /// Label for the skip button on the onboarding page
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// Label for the next button on the onboarding page
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Label for the get started button on the final onboarding page
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// Semantics label for the skip button
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get skipSemantics;

  /// Semantics label for the next button
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextSemantics;

  /// Semantics label for the get started button
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStartedSemantics;

  /// Semantics label for each onboarding page
  ///
  /// In en, this message translates to:
  /// **'Onboarding page {pageNumber}'**
  String onboardingPageSemantics(int pageNumber);

  /// Title for the mother form page app bar
  ///
  /// In en, this message translates to:
  /// **'Welcome, Please Fill Below Form!'**
  String get motherFormTitle;

  /// Error message when full name is empty
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get fullNameRequiredError;

  /// Label for the gender selection section
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGenderLabel;

  /// Label for the male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleGenderOption;

  /// Label for the female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleGenderOption;

  /// Label for the age selection section
  ///
  /// In en, this message translates to:
  /// **'Select Your Age'**
  String get selectAgeLabel;

  /// Label showing the selected age with placeholder
  ///
  /// In en, this message translates to:
  /// **'Selected Age: {age}'**
  String selectedAgeLabel(int age);

  /// Label for the height input section
  ///
  /// In en, this message translates to:
  /// **'Enter Your Height'**
  String get enterHeightLabel;

  /// Error message when height is empty
  ///
  /// In en, this message translates to:
  /// **'Height is required'**
  String get heightRequiredError;

  /// Error message when height is not a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get heightInvalidError;

  /// Error message when blood pressure is empty
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure is required'**
  String get bloodPressureRequiredError;

  /// Error message when blood pressure format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter valid blood pressure (e.g., 120/80)'**
  String get bloodPressureInvalidError;

  /// Label for the weight input section
  ///
  /// In en, this message translates to:
  /// **'Enter Your Weight'**
  String get enterWeightLabel;

  /// Error message when weight is empty
  ///
  /// In en, this message translates to:
  /// **'Weight is required'**
  String get weightRequiredError;

  /// Error message when weight is not a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get weightInvalidError;

  /// Label for the pregnancy start date input field
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Start Date'**
  String get pregnancyStartDateLabel;

  /// Text shown when pregnancy start date is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get pregnancyStartDateNotSet;

  /// Label for the pregnancy start date section
  ///
  /// In en, this message translates to:
  /// **'When Did You Become Pregnant?'**
  String get pregnancyStartDateQuestion;

  /// Label showing the pregnancy duration with placeholders
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Duration: {weeks} weeks and {days} days'**
  String pregnancyDurationLabel(int weeks, int days);

  /// Label for the health conditions selection section
  ///
  /// In en, this message translates to:
  /// **'Select Any Applicable Health Conditions'**
  String get healthConditionsLabel;

  /// Label for the diabetes health condition option
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get healthConditionDiabetes;

  /// Label for the hypertension health condition option
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get healthConditionHypertension;

  /// Label for the asthma health condition option
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get healthConditionAsthma;

  /// Label for the heart disease health condition option
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get healthConditionHeartDisease;

  /// Label for the thyroid issues health condition option
  ///
  /// In en, this message translates to:
  /// **'Thyroid Issues'**
  String get healthConditionThyroidIssues;

  /// Label for the other health condition option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get healthConditionOther;

  /// Label for the health issue description input field
  ///
  /// In en, this message translates to:
  /// **'Describe Your Health Issue'**
  String get healthIssueDescriptionLabel;

  /// Label for the submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// Title for the submission confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Submission'**
  String get confirmSubmissionTitle;

  /// Message in the submission confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit the form?'**
  String get confirmSubmissionMessage;

  /// Label for the cancel button in the confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Error message when required fields are not filled
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields!'**
  String get requiredFieldsError;

  /// Error message when weight or height is not a valid number
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numbers for weight and height!'**
  String get invalidNumberError;

  /// Success message when the form is submitted
  ///
  /// In en, this message translates to:
  /// **'Form submitted successfully!'**
  String get formSubmitSuccess;

  /// Error message when form submission fails with placeholder
  ///
  /// In en, this message translates to:
  /// **'Error submitting form: {error}'**
  String formSubmitError(Object error);

  /// No description provided for @popupNotifications.
  ///
  /// In en, this message translates to:
  /// **'Pop-up Notifications'**
  String get popupNotifications;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
