// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get pageTitleNotificationDetail => 'የማሳወቂያ ዝርዝሮች';

  @override
  String get messageLabel => 'መልእክት';

  @override
  String deliveredLabel(Object date) {
    return 'ተልኳል: $date';
  }

  @override
  String get seenLabel => 'ተመልክቷል';

  @override
  String get unreadLabel => 'አልተነበበም';

  @override
  String get relevanceLabel => 'ጠቀሜት';

  @override
  String get pageTitleNotificationHistory => 'የማሳወቂያ ታሪክ';

  @override
  String get noNotifications => 'ገና ምንም ማሳወቂያ የለም';

  @override
  String errorLabel(Object error) {
    return 'ስህተት: $error';
  }

  @override
  String get pageTitleCommunity => 'ማህበረሰብ';

  @override
  String get whatsOnYourMind => 'ምን እያሰብክ ነው';

  @override
  String get noPosts => 'ምንም ልጥፍ የለም። አዲስ ፍጠር';

  @override
  String get pageTitleProfile => 'መገለጫ';

  @override
  String get languageSettings => 'የቋንቋ ቅንብሮች';

  @override
  String get languageEnglish => 'እንግሊዝኛ';

  @override
  String get languageAmharic => 'አማርኛ';

  @override
  String get viewNotification => 'ማሳወቂያ ተመልከት';

  @override
  String get pageTitleHome => 'መነሻ';

  @override
  String get pageTitleHealthMetrics => 'የጤና መለኪያዎች';

  @override
  String get pageTitleEducation => 'ትምህርት';

  @override
  String get pageTitleFavorites => 'ተወዳጆች';

  @override
  String get pageTitleWeeklyTip => 'ሳምንታዊ ምክር';

  @override
  String get pageTitleJournal => 'ዕለታዊ ማስታወሻ';

  @override
  String greeting(String name) {
    return 'ሰላም፣ $name!';
  }

  @override
  String get pregnancyJourney => 'የእርግዝና ጉዞ';

  @override
  String get weeksLabel => 'ሳምንታት';

  @override
  String get daysLabel => 'ቀናት';

  @override
  String get weeklyTips => 'ሳምንታዊ ምክሮች';

  @override
  String get noTipsYet => 'እስካሁን ምንም ምክሮች የሉም—ጥቂት ያክሉ!';

  @override
  String get exploreFeatures => 'ተግባራትን ያስሱ';

  @override
  String get featureCalendar => 'ቀን መቁጠሪያ';

  @override
  String get featureCalendarDescription => 'ቀጠሮዎችን መርሐ ግብር ያስይዙ';

  @override
  String get featureHealthMetrics => 'የጤና መለኪያዎች';

  @override
  String get featureHealthMetricsDescription => 'ጤናዎን ይፈትሹ';

  @override
  String get featureJournal => 'ዕለታዊ ማስታወሻ';

  @override
  String get featureJournalDescription => 'ሀሳቦችዎን ይፃፉ';

  @override
  String get featureNameSuggestion => 'ስም መጠየቅ';

  @override
  String get featureNameSuggestionDescription => 'የሕፃን ስሞችን ይፈልጉ';

  @override
  String get noUserLoggedIn => 'ምንም ተጠቃሚ አልገባም';

  @override
  String failedToLoadProfile(Object error) {
    return 'መገለጫ መጫን አልተሳካም: $error';
  }

  @override
  String weekLabel(Object week) {
    return 'ሳምንት $week';
  }

  @override
  String get noTitle => 'No Title';

  @override
  String get pageTitleHealthArticle => 'የጤና ጽሑፍ';

  @override
  String get noDiaryEntries => 'እስካሁን ምንም የዴስክ ግቤቶች የሉም።';

  @override
  String errorLoadingEntries(Object error) {
    return 'ግቤቶችን መጫን ላይ ስህተት: $error';
  }

  @override
  String get addedToFavorites => 'ወደ ተወዳጆች ተጨምሯል!';

  @override
  String get removedFromFavorites => 'ከተወዳጆች ተወግዷል!';

  @override
  String errorUpdatingFavorite(Object error) {
    return 'ተወዳጅ ማዘመን ላይ ስህተት: $error';
  }

  @override
  String get noContent => 'ይዘት የለም';

  @override
  String get moreButton => 'ተጨማሪ >>>';

  @override
  String get lessButton => 'ያነሰ >>>';

  @override
  String postedAt(Object date) {
    return 'ተለጠፈ በ: $date';
  }

  @override
  String weekLabelWithNumber(int week) {
    return 'ሳምንት $week';
  }

  @override
  String get favoriteEntriesTitle => 'ተወዳጅ ግቤቶች';

  @override
  String get noFavoriteEntries => 'እስካሁን ምንም ተወዳጅ ግቤቶች የሉም።';

  @override
  String get refreshButton => 'አድስ';

  @override
  String get showMore => 'ተጨማሪ >>>';

  @override
  String get showLess => 'ያነሰ >>>';

  @override
  String get postedAtLabel => 'የተለጠፈበት ቀን';

  @override
  String get bottomNavHome => 'መነሻ';

  @override
  String get bottomNavCommunity => 'ማህበረሰብ';

  @override
  String get bottomNavEducation => 'ትምህርት';

  @override
  String get bottomNavConsult => 'አማካሪ';

  @override
  String get failedToLoadUserData => 'የተጠቃሚ ውሂብ መጫን አልተሳካም';

  @override
  String errorLoadingData(Object error) {
    return 'ስህተት ተከስቷል: $error';
  }

  @override
  String get consultPageComingSoon => 'የአማካሪ ገፅ (በቅርቡ ይመጣል)';

  @override
  String get editProfileTitle => 'መገለጫ አርትዕ';

  @override
  String get chooseFromGallery => 'ከጋለሪ ምረጥ';

  @override
  String get takePhoto => 'ፎቶ አንሳ';

  @override
  String get personalInformation => 'የግል መረጃ';

  @override
  String get fullNameLabel => 'ሙሉ ስም';

  @override
  String get ageLabel => 'ዕድሜ';

  @override
  String get weightLabel => 'ክብደት';

  @override
  String get heightLabel => 'ቁመት';

  @override
  String get bloodPressureLabel => 'የደም ግፊት (ለምሳሌ፣ 120/80)';

  @override
  String get selectHealthConditions => 'ተፈጻሚ የጤና ሁኔታዎችን ምረጥ';

  @override
  String get describeHealthIssue => 'የጤና ችግርህን ግለጽ';

  @override
  String get healthIssueHint => 'የጤና ታሪክህን ወይም ችግሮችህን እዚህ ግለጽ...';

  @override
  String get saveProfileButton => 'መገለጫ አስቀምጥ';

  @override
  String failedToUpdateProfile(Object error) {
    return 'መገለጫ ማዘመን አልተሳካም: $error';
  }

  @override
  String get cameraPermissionDenied => 'የካሜራ ፍቃድ ተከልክሏል';

  @override
  String get galleryPermissionDenied => 'የጋለሪ ፍቃድ ተከልክሏል';

  @override
  String get imageTooLarge => 'ምስሉ በጣም ትልቅ ነው፣ እባክህ ትንሽ ምረጥ';

  @override
  String errorPickingImage(Object error) {
    return 'ምስል መምረጥ ላይ ስህተት: $error';
  }

  @override
  String get profileUpdatedSuccessfully => 'መገለጫ በተሳካ ሁኔታ ታድሷል!';

  @override
  String weightUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'kg': 'ኪግ',
        'lbs': 'ፓውንድ',
        'other': '$unit',
      },
    );
    return '$_temp0';
  }

  @override
  String heightUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'cm': 'ሴሜ',
        'ft': 'ፊት',
        'other': '$unit',
      },
    );
    return '$_temp0';
  }

  @override
  String healthCondition(String condition) {
    String _temp0 = intl.Intl.selectLogic(
      condition,
      {
        'diabetes': 'ስኳር በሽታ',
        'hypertension': 'ከፍተኛ የደም ግፊት',
        'asthma': 'አስም',
        'heartDisease': 'የልብ በሽታ',
        'thyroidIssues': 'የታይሮይድ ችግሮች',
        'other': 'ሌላ',
        'other': '$condition',
      },
    );
    return '$_temp0';
  }

  @override
  String errorMarkingAsSeen(Object error) {
    return 'እንደተመለከተ ምልክት ማድረግ ላይ �ስህተት: $error';
  }

  @override
  String get tapToView => 'መታ ያድርጉ ለመመልከት';

  @override
  String get notificationChannelName => 'የየቀኑ ምክር';

  @override
  String get notificationChannelDescription => 'የጤና ምክሮች በየ4 ቀናት';

  @override
  String fallbackTipTitle(int index) {
    return 'ምክር $index';
  }

  @override
  String get fallbackTipBody => 'ለመከረው ሐኪምዎን ያማክሩ።';

  @override
  String relevanceLabelWithValue(String value) {
    return 'ተገቢነት: $value';
  }

  @override
  String get genderLabel => 'ጾታ';

  @override
  String get genderSelectionError => 'እባክዎ ጾታ ይምረጡ';

  @override
  String get enterHealthData => 'የጤና ውሂብ ያስገቡ:';

  @override
  String get bpSystolicLabel => 'Blood Pressure Systolic (mmHg)';

  @override
  String get bpDiastolicLabel => 'Blood Pressure Diastolic (mmHg)';

  @override
  String get heartRateLabel => 'የልብ መጠጥ (bpm)';

  @override
  String get bodyTemperatureLabel => 'የሰውነት ሙቀት (°C)';

  @override
  String get weightLabelKg => 'ክብደት (ኪግ)';

  @override
  String get saveDataButton => 'ውሂብ አስቀምጥ';

  @override
  String get recommendationsTitle => 'ምክሮች:';

  @override
  String get healthTrendsTitle => 'የጤና መልካም ሁኔታዎች:';

  @override
  String get noDataAvailable => 'ውሂብ የለም።';

  @override
  String get dataSavedSuccessfully => 'ውሂብ በተሳካ ሁኔታ ተቀምጧል!';

  @override
  String get failedToSaveData => 'ውሂብ መቀመጥ አልተሳካም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get invalidValuesError => 'እባክዎ ሁሉንም መስፈርቶች ትክክለኛ እሴቶችን ያስገቡ።';

  @override
  String get tempScaledLabel => 'የሙቀት መጠን (°C x 5)';

  @override
  String bpLowRecommendation(int bpSys, int bpDia) {
    return 'የደም ግፊትህ ዝቅተኛ እንደሆነ ይመስላል (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg)። ይህ በውሃ እጥበት፣ በመቀነስ ወይም በሌሎች ምክንያቶች ሊኖር ይችላል። ለመቀነስ የሚረዱበትን ጥሩ የጤና መልካም ሁኔታ ይቀጥሉ፣ በየቀኑ ውሃ መጠጣትን ያሳድጉ (8-10 ጋላ ይዘት) እና የእህቴ ምግብ መቀነስ ይፈልጉ። ከዚያም በተለቀቀ ጊዜ ለማስጠበቅ ለመንገድ እና ለማደንቀፍ ከሆነ ለማድረግ ለመልካም አቅም የሚያስፈልግ ነው።';
  }

  @override
  String bpHighRecommendation(int bpSys, int bpDia) {
    return 'የደም ግፊትህ ከፍተኛ ነው (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg)፣ ይህም ሊያመልክት የሚችል ነው የከፍተኛ የደም ግፊት ነው። ለመቀነስ የሚረዱበትን ጥሩ የጤና መልካም ሁኔታ ይቀጥሉ፣ በየቀኑ ውሃ መጠጣትን ያሳድጉ (8-10 ጋላ ይዘት) እና የእህቴ ምግብ መቀነስ ይፈልጉ። ከዚያም በተለቀቀ ጊዜ ለማስጠበቅ ለመንገድ እና ለማደንቀፍ ከሆነ ለማድረግ ለመልካም አቅም የሚያስፈልግ ነው።';
  }

  @override
  String bpNormalRecommendation(int bpSys, int bpDia) {
    return 'የደም ግፊትህ (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg) መደበኛ ነው። ይህን ለመቀነስ የሚረዱበትን ጥሩ የጤና መልካም ሁኔታ ይቀጥሉ፣ በየቀኑ ውሃ መጠጣትን ያሳድጉ (8-10 ጋላ ይዘት) እና የእህቴ ምግብ መቀነስ ይፈልጉ። ከዚያም በተለቀቀ ጊዜ ለማስጠበቅ ለመንገድ እና ለማደንቀፍ ከሆነ ለማድረግ ለመልካም አቅም የሚያስፈልግ ነው።';
  }

  @override
  String hrLowRecommendation(int hr) {
    return 'የልብ መጠጡ ($hr bpm) ዝቅተኛ ነው። ይህ ለጤና ያለፈ ሰዎች መደበኛ ነው፣ ግን ከፍተኛ አይነት እንቅስቃሴ አልተካሄድም ወይም መቀነስ እንደሚሰማብዎ መመከር ይገባል። የልብ መጠጥን ለመጨመር እንቁስቋሴዎን ያሳድጉ በሚያደርግበት ጊዜ የልብ መጠጡን ያረጋግጡ።';
  }

  @override
  String hrHighRecommendation(int hr) {
    return 'የልብ መጠጡ ($hr bpm) ከፍተኛ ነው፣ ይህም በጭንቀት፣ በቡና ወይም በግብዓት ሊኖር ይችላል። ለመቀነስ የልብ መጠጡን ያረጋግጡ በሚያደርግበት ጊዜ የልብ መጠጡን ያረጋግጡ።';
  }

  @override
  String hrNormalRecommendation(int hr) {
    return 'የልብ መጠጡ ($hr bpm) መደበኛ ነው። ይህን ለመቀነስ የልብ መጠጡን ያረጋግጡ በሚያደርግበት ጊዜ የልብ መጠጡን ያረጋግጡ።';
  }

  @override
  String tempLowRecommendation(double temp) {
    return 'የሰውነት ሙቀት ($temp°C) ከመካከለኛ መከላከያ በታች ነው፣ ይህም በተቆጣጠረ ሁኔታ ወይም በተቀንሶ መጠን ሊኖር ይችላል። ለመቀነስ የሰውነት ሙቀትዎን ያረᜌጋግጡ በሚያደርግበት ጊዜ የሰውነት ሙቀትዎን ያረጋግጡ።';
  }

  @override
  String tempHighRecommendation(double temp) {
    return 'የሰውነት ሙቀት ($temp°C) ከፍተኛ ነው፣ ይህም ሊያመልክት የሚችል ነው የተቆጣጠረ ሁኔታ ነው። ለመቀነስ የሰውነት ሙቀትዎን ያረጋግጡ በሚያደርግበት ጊዜ የሰውነት ሙቀትዎን ያረጋግጡ።';
  }

  @override
  String tempNormalRecommendation(double temp) {
    return 'የሰውነት ሙቀት ($temp°C) መደበኛ ነው። ይህን ለመቀነስ የሰውነት ሙቀትዎን ያረጋግጢ በሚያደርግበት ጊዜ የሰውነት ሙቀትዎን ያረጋግጡ።';
  }

  @override
  String weightLowRecommendation(double weight) {
    return 'ክብደትህ ($weight kg) ዝቅተኛ ነው። ይህን ለመቀነስ የሰውነት ክብደትዎን ያረጋግጡ በሚያደርግበት ጊዜ የሰውነት ክብደትዎን ያረጋግጡ።';
  }

  @override
  String weightHighRecommendation(double weight) {
    return 'ክብደትህ ($weight kg) ከፍተኛ ነው። ይህን ለመቀነስ የሰውነት ክብደትዎን ያረጋግጡ በሚያደርግበት ጊዜ የሰውነት ክብደትዎን ያረጋግጡ።';
  }

  @override
  String weightNormalRecommendation(double weight) {
    return 'ክብደትህ ($weight kg) መደበኛ ነው። ይህን ለመቀነስ የሰውነት ክብደትዎን ያረጋግጡ በሚያደርግበት ጊዜ የሰውነት ክብደትዎን ያረጋግጡ።';
  }

  @override
  String bpSysIncreasedRecommendation(int prevBpSys, int bpSys) {
    return 'የደም ግፊትህ (Systolic: $bpSys mmHg) ከፍተኛ ነው ከፊተኛ መጠን (ከ$prevBpSys ወደ $bpSys) በላይ ነው። ይህ በጊዜ ሁኔታ ወይም በተመጣጣኝ ምግብ ሊኖር ይችላል፣ ግን በተቃራይ ጊዜ ይመከሩ።';
  }

  @override
  String hrIncreasedRecommendation(int prevHr, int hr) {
    return 'የልብ መጠጡ ($hr bpm) ከፊተኛ መጠን (ከ$prevHr ወደ $hr) በላይ ነው። ይህ በጊዜ ሁኔታ ወይም በተመጣጣኝ እንቁስቋሴ ሊኖር ይችላል፣ ግን በተቃራይ ጊዜ ይመከሩ።';
  }

  @override
  String weightIncreasedRecommendation(double prevWeight, double weight) {
    return 'ክብደትህ ($weight kg) ከፊተኛ መጠን (ከ$prevWeight ወደ $weight) በላይ ነው። ይህ በውሃ መጠጣት ወይም በተመጣጣኝ ምግብ ሊኖር ይችላል፣ ግን በተቃራይ ጊዜ ይመከሩ።';
  }

  @override
  String allVitalsNormalRecommendation(int bpSys, int bpDia, int hr, double temp, double weight) {
    return 'ሁሉም የመጨረሻ የጤና መለኪያዎችህ (BP: $bpSys/$bpDia mmHg, HR: $hr bpm, Temp: $temp°C, Weight: $weight kg) መደበኛ ናቸው። በጣም ጥሩ! ጤናማ ልማቶችህን ቀጥል፣ ሚዛናዊ ምግብ፣ መደበኛ እንቅስቃሴ (ሳምንታዊ 150 ደቂቃዎች)፣ እና ተከታታይ እንቅልፍ (በሌሊት 7-9 ሰዓታት) ለመቀጠል።';
  }

  @override
  String get noDataRecommendation => 'እስካሁን ውሂብ የለም። የጤና መለኪያዎችህን በማስገባት ግላዊ ምክሮችን ለመቀበል ጀምር።';

  @override
  String tooltipBpSys(int value) {
    return 'BP Sys: $value mmHg';
  }

  @override
  String tooltipHr(int value) {
    return 'HR: $value bpm';
  }

  @override
  String tooltipTemp(double value) {
    return 'የሙቀት መጠን: $value°C';
  }

  @override
  String tooltipWeight(double value) {
    return 'ክብደት: $value kg';
  }

  @override
  String get boysLabel => 'ወንዶች';

  @override
  String get femaleGender => 'የሴት ጾታ';

  @override
  String get girlsLabel => 'ሴቶች';

  @override
  String get maleGender => 'የወንድ ጾታ';

  @override
  String noNamesAvailable(String category) {
    return 'ለ$category ምንም ስሞች የሉም';
  }

  @override
  String get pageTitleNameSuggestion => 'የሕፃን ስም መጠየቂያ';

  @override
  String get tabAll => 'ሁሉም';

  @override
  String get tabChristian => 'ክርስቲያን';

  @override
  String get tabMuslim => 'ሙስሊም';

  @override
  String get addNoteLabel => 'ማስቀመጥ ምስክር';

  @override
  String get deleteAction => 'መሰረዝ';

  @override
  String errorDeletingNote(Object error) {
    return 'የምስክር መሰረዝ ላይ ስህተት: $error';
  }

  @override
  String get loginPrompt => 'እባክህ መግባት ይፈልጋሉ';

  @override
  String get noNotesMatchSearch => 'ምንም ምስክሮች ከመፈለጉ ጋር አይዛመዱም';

  @override
  String get noNotesYet => 'እስካሁን ምንም ምስክር የለም። አንድ ያክሉ!';

  @override
  String get searchHint => 'የምስክሮችን በአርዕስት መፈለግ...';

  @override
  String get aboutSection => 'ስለ';

  @override
  String get appointmentAccepted => 'ቀጠሮ ተቀባይነት አግኝቷል';

  @override
  String get appointmentCancelled => 'ቀጠሮ ተሰርዟል';

  @override
  String get appointmentCancelledMessage => 'ይህ ቀጠሮ ተሰርዟል። የቪዲዮ ጥሪው ይጠናቀቃል።';

  @override
  String appointmentWithDoctor(String doctorName) {
    return '$doctorName ጋር ቀጠሮ';
  }

  @override
  String get appointmentsLabel => 'ቀጠሮዎች';

  @override
  String get availableDoctors => 'የሚገኙ ዶክተሮች';

  @override
  String get availableTimeSlots => 'የሚገኙ የጊዜ ቦታዎች፡';

  @override
  String get beforeJoining => 'ከመቀላቀልዎ በፊት፡';

  @override
  String get bookAppointment => 'ቀጠሮ ይያዙ';

  @override
  String bookAppointmentWith(String fullName) {
    return '$fullName ጋር ቀጠሮ ይያዙ';
  }

  @override
  String get bookNewAppointmentTooltip => 'አዲስ ቀጠሮ ይያዙ';

  @override
  String get bookingLabel => 'መያዣ';

  @override
  String callEnded(Object error) {
    return 'ጥሪ አልቋል፡ $error';
  }

  @override
  String get connectedToCall => 'ወደ ጥሪ ተገናኝቷል';

  @override
  String get connectedToServer => 'ከአገልጋይ ጋር ተገናኝቷል';

  @override
  String get connectingToCall => 'ወደ ጥሪ በመገናኘት ላይ...';

  @override
  String get contactInformation => 'የመገናኛ መረጃ';

  @override
  String get copiedToClipboard => 'ወደ ክሊፕቦርድ ተቀድቷል';

  @override
  String get copyLinkTooltip => 'አገናኝ ቅዳ';

  @override
  String get couldNotCreateProfile => 'የተጠቃሚ መገለጫ መፍጠር አልተሳካም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String doctorProfile(String fullName, String speciality) {
    return 'ዶክተር መገለጫ፡ $fullName፣ $speciality';
  }

  @override
  String doctorRating(String fullName, String speciality) {
    return 'ዶክተር $fullName፣ $speciality፣ 4.5 ደረጃ';
  }

  @override
  String get doctorsLabel => 'ዶክተሮች';

  @override
  String get emailLabel => 'ኢሜይል';

  @override
  String get ensureStableConnection => 'የተረጋጋ የበይነመረብ ግንኙነት እንዳለዎት ያረጋግጡ';

  @override
  String get errorJoiningCall => 'ጥሪ መቀላቀል ላይ ስህተት';

  @override
  String get errorPrefix => 'ስህተት';

  @override
  String errorSendingRequest(Object error) {
    return 'ጥያቄ መላክ ላይ ስህተት፡ $error';
  }

  @override
  String get findQuietSpace => 'ለእርስዎ ምክክር ጸጥ ያለ፣ የግል ቦታ ያግኙ';

  @override
  String get haveQuestionsReady => 'ለዶክተሩ ጥያቄዎችዎን ያዘጋጁ';

  @override
  String get inCall => 'በጥሪ ውስጥ';

  @override
  String get invalidDateFormat => 'የተሳሳተ የቀን ቅርጸት';

  @override
  String get joinNow => 'አሁን ይቀላቀሉ';

  @override
  String get joinVideoCall => 'የቪዲዮ ጥሪ ይቀላቀሉ';

  @override
  String get joining => 'በመቀላቀል ላይ...';

  @override
  String get joiningCall => 'ጥሪ በመቀላቀል ላይ...';

  @override
  String get later => 'በኋላ';

  @override
  String get meetingInformation => 'የስብሰባ መረጃ';

  @override
  String get motherAppTitle => 'የእናቶች መተግበሪያ';

  @override
  String get navigateToAppointments => 'ወደ ቀጠሮዎች ገፅ ይሂዱ';

  @override
  String get navigateToBooking => 'ወደ መያዣ ገፅ ይሂዱ';

  @override
  String get navigateToDoctors => 'ወደ ዶክተሮች ገፅ ይሂዱ';

  @override
  String get newMeetingLinkAvailable => 'አዲስ የስብሰባ አገናኝ ይገኛል';

  @override
  String get newMeetingLinkMessage => 'አዲስ የቪዲዮ ኮንፈረንስ አገናኝ ይገኛል። በአዲሱ አገናኝ መቀላቀል ይፈልጋሉ?';

  @override
  String get noAcceptedAppointments => 'ምንም ተቀባይነት ያላቸው ቀጠሮዎች የሉም።\nተቀባይነት ያገኙ ቀጠሮዎች እዚህ ይታያሉ።';

  @override
  String get noAvailabilityFound => 'ለዚህ ዶክተር ምንም መገኘት አልተገኘም።';

  @override
  String get noDateAvailable => 'ምንም ቀን የለም';

  @override
  String get noDescriptionAvailable => 'ምንም መግለጫ የለም';

  @override
  String get noDoctorsAvailable => 'ምንም ዶክተሮች የሉም';

  @override
  String get noPendingAppointments => 'ምንም በመጠባበቅ ላይ ያሉ ቀጠሮዎች የሉም።\nየሚልኳቸው ጥያቄዎች እዚህ ይታያሉ።';

  @override
  String get noRejectedAppointments => 'ምንም ውድቅ የተደረጉ ቀጠሮዎች የሉም።\nውድቅ የተደረጉ ቀጠሮዎች እዚህ ይታያሉ።';

  @override
  String get notAvailable => 'አይገኝም';

  @override
  String get notConnected => 'አልተገናኘም - ቀጠሮዎች ላይላኩ ይችላሉ';

  @override
  String get notSpecified => 'አልተገለጸም';

  @override
  String get okLabel => 'እሺ';

  @override
  String get pageTitleAppointments => 'የእኔ ቀጠሮዎች';

  @override
  String get phoneLabel => 'ስልክ';

  @override
  String get pleaseSelectDateTime => 'እባክዎ ቀን እና ሰዓት ይምረጡ';

  @override
  String get ratingLabel => '4.5 (245 ግምገማዎች)';

  @override
  String get readyToJoin => 'መቀላቀል ዝግጁ ነው';

  @override
  String get refreshAppointmentsTooltip => 'ቀጠሮዎችን አድስ';

  @override
  String get requestAppointment => 'ቀጠሮ ጠይቅ';

  @override
  String get requestSent => 'የቀጠሮ ጥያቄ ተልኳል! የዶክተር ፈቃድ በመጠባበቅ ላይ።';

  @override
  String get rescheduleAppointment => 'ቀጠሮ እንደገና ማስያዝ';

  @override
  String get selectDateTime => 'ቀን እና ሰዓት ይምረጡ';

  @override
  String specialityLabel(String speciality) {
    return 'ልዩ ሙያ፦ $speciality';
  }

  @override
  String get startCall => 'ጥሪ ይጀምሩ';

  @override
  String get startVideoCall => 'ቪዲዮ ጥሪ ይጀምሩ';

  @override
  String get statusAccepted => 'ተቀባይነት አግኝቷል';

  @override
  String get statusCancelled => 'ተሰርዟል';

  @override
  String get statusPending => 'በመጠባበቅ ላይ';

  @override
  String get statusRejected => 'ተቀባይነት አላገኘም';

  @override
  String timeZoneLabel(String timeZone) {
    return 'ሰዓት ሰቅ $timeZone';
  }

  @override
  String get upcomingAppointments => 'የቀጠሮ ቀናት';

  @override
  String get viewProfile => 'መገለጫ ይመልከቱ';

  @override
  String get waitingForDoctor => 'ዶክተሩን እየጠበቅን ነው።';

  @override
  String get yourMeetingLink => 'የእርስዎ የስብሰባ አገናኝ';

  @override
  String get retryButton => 'እንደገና ሞክር';

  @override
  String get searchNotesHint => 'የእርስዎን ማስታወሻዎች ይፈልጉ...';

  @override
  String get pleaseLogIn => 'እባክዎ ለመቀጠል ይግቡ';

  @override
  String get noteDeleted => 'ማስታወሻ በተሳካ ሁኔታ ተሰርዟል';

  @override
  String get appName => 'አዴ እርዳታ መተግበሪያ';

  @override
  String get noInternetTitle => 'የበይነመረብ ግንኙነት የለም';

  @override
  String get noInternetMessage => 'እባክዎ የበይነመረብ ግኍኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ።';

  @override
  String get genderFemale => 'ሴት';

  @override
  String get genderMale => 'ወንድ';

  @override
  String get genderOther => 'ሌላ';

  @override
  String get editProfile => 'መገለጫ አርትዕ';

  @override
  String get themeMode => 'ገጽታ ሁኔታ';

  @override
  String get consultationFee => 'የምክር ክፍያ';

  @override
  String get unknownName => 'ያልታወቀ ስም';

  @override
  String get welcomeMessage => 'ወደ አዴ እርዳታ መተግበሪያ እንኳን ደህና መጡ!';

  @override
  String get testCameraMic => 'ካሜራዎን እና ማይክሮፎንዎን ይሞክሩ';

  @override
  String get yourDoctorWillJoin => 'ዶክተርዎ በቅርቡ ወደ ስብሰባው ይቀላቀላል';

  @override
  String roomName(Object roomName) {
    return 'ክፍል: $roomName';
  }

  @override
  String statusLabel(Object status) {
    return 'ሁኔታ: $status';
  }

  @override
  String scheduledFor(Object date) {
    return 'የተያዘለት: $date';
  }

  @override
  String get videoConsultationTitle => 'የቪዲዮ ምክክር';

  @override
  String get videoConsultationMessage => 'የእርስዎ የቪዲዮ ምክክር ለመጀመር ዝግጁ ነው።';

  @override
  String tabPending(int count) {
    return 'በመጠባበቅ ላይ ($count)';
  }

  @override
  String tabAccepted(int count) {
    return 'ተቀባይነት ያለው ($count)';
  }

  @override
  String tabRejected(int count) {
    return 'ውድቅ የተደረገ ($count)';
  }

  @override
  String statusPrefix(String status) {
    return 'ሁኔታ: $status';
  }

  @override
  String get retryLabel => 'እንደገና ሞክር';

  @override
  String errorFetchingUserData(String error) {
    return 'የተጠቃሚ መረጃ ማግኘት ላይ ስህተት: $error';
  }

  @override
  String errorFetchingComments(String error) {
    return 'አስተያየቶችን ማግኘት ላይ ስህተት: $error';
  }

  @override
  String get commentCannotBeEmpty => 'አስተያየት ባዶ ሊሆን አይችልም';

  @override
  String errorAddingComment(String error) {
    return 'አስተያየት መጨመር ላይ ስህተት: $error';
  }

  @override
  String get commentDeletedSuccessfully => 'አስተያየት በተሳካ ሁኔታ ተሰርዟል';

  @override
  String errorDeletingComment(String error) {
    return 'አስተያየት መሰረዝ ላይ ስህተት: $error';
  }

  @override
  String get postDetailTitle => 'የመልእክት ዝርዝሮች';

  @override
  String profileOf(String fullName) {
    return 'የ$fullName መገለጫ';
  }

  @override
  String likesCountText(int count) {
    return '$count መውደዶች';
  }

  @override
  String commentsCountText(int count) {
    return '$count አስተያየቶች';
  }

  @override
  String commentBy(String fullName) {
    return 'አስተያየት በ$fullName';
  }

  @override
  String deleteCommentBy(String fullName) {
    return 'አስተያየት በ$fullName ሰርዝ';
  }

  @override
  String get noCommentsYet => 'እስካሁን ምንም አስተያየቶች የሉም';

  @override
  String get writeCommentHint => 'አስተያየት ይፃፉ...';

  @override
  String get sendCommentTooltip => 'አስተያየት ላክ';

  @override
  String get unableToLoadChat => 'ውይይት መጫን አልተቻለም';

  @override
  String get chatServiceUnavailable => 'የውይይት አገልግሎት በአሁኑ ጊዜ አይገኝም';

  @override
  String get pleaseLogInChat => 'እባክዎ ውይይት ለመድረስ ይግቡ';

  @override
  String databaseError(String message) {
    return 'የውሂብ ጎታ ስህተት: $message';
  }

  @override
  String get networkError => 'የአውታረ መረብ ስህተት፣ እባክዎ ግንኙነትዎን ያረጋግጡ';

  @override
  String failedToSendMessage(String error) {
    return 'መልእክት መላክ አልተሳካም: $error';
  }

  @override
  String startChatting(String receiverName) {
    return '$receiverName ጋር ውይይት ይጀምሩ';
  }

  @override
  String get chatUnavailableHint => 'ውይይት በአሁኑ ጊዜ አይገኝም';

  @override
  String get typeMessageHint => 'መልእክት ይፃፉ...';

  @override
  String get sendMessageTooltip => 'መልእክት ላክ';

  @override
  String postBy(String fullName) {
    return 'መልእክት በ$fullName';
  }

  @override
  String get editPost => 'መልእክት አርትዕ';

  @override
  String get deletePost => 'መልእክት ሰርዝ';

  @override
  String get unlikePost => 'መልእክት አለመውደድ';

  @override
  String get likePost => 'መልእክት ውደድ';

  @override
  String get commentOnPost => 'በመልእክት ላይ አስተያየት ስጥ';

  @override
  String get commentPost => 'አስተያየት';

  @override
  String get imageSizeError => 'የምስል መጠን ከ5ሜባ በላይ ነው';

  @override
  String get emptyContentError => 'የልጥፍ ይዘት ባዶ መሆን አይችልም';

  @override
  String get userDataNotLoaded => 'የተጠቃሚ ውሂብ አልተጫነም፣ እባክዎ እንደገና ይሞክሩ';

  @override
  String errorSavingPost(String error) {
    return 'ልጥፍ ማስቀመጥ ላይ ስህተት: $error';
  }

  @override
  String get closeTooltip => 'ዝጋ';

  @override
  String get editPostTitle => 'ልጥፍ አርትዕ';

  @override
  String get postButton => 'ለጥፍ';

  @override
  String get updateButton => 'አዘምን';

  @override
  String get removeImageTooltip => 'ምስል አስወግድ';

  @override
  String get addImageTooltip => 'ምስል ጨምር';

  @override
  String get createPostTitle => 'ልጥፍ ፍጠር';

  @override
  String errorFetchingUser(String error) {
    return 'የተጠቃሚ ውሂብ ማግኘት ላይ ስህተት: $error';
  }

  @override
  String get searchPosts => 'ልጥፎችን ፈልግ';

  @override
  String get createNewPost => 'አዲስ ልጥፍ ፍጠር';
}
