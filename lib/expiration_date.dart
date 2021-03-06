import 'regexs.dart';
import 'validation_results.dart';

/// Validates the expiration dates on credit cards

/// The default number of years into the future a card is valid. Set to 19
/// i.e. if the current year is 2019 then a valid card would not have an expiration date greater than 2038
const int DEFAULT_NUM_YEARS_IN_FUTURE = 19;

/// Validates the card's expiration date based on the standard that no credit cards
  ValidationResults validateExpirationDate(String expDateStr) {
    if (expDateStr == null || expDateStr.isEmpty) {
      return ValidationResults(
        isValid: false,
        isPotentiallyValid: false,
        message: 'No date given',
      );
    }

    List<String> monthAndYear = _parseDate(expDateStr);
    if (monthAndYear == null) {
      return ValidationResults(
        isValid: false,
        isPotentiallyValid: true,
        message: 'Invalid date format',
      );
    }

    ExpMonthValidationResults monthValidation =
        _validateExpMonth(monthAndYear[0]);
    ExpYearValidationResults yearValidation =
        _validateExpYear(monthAndYear[1]);

    if (monthValidation.isValid) {
      if (yearValidation.expiresThisYear) {
        // If the card expires this year then tell whether or not it has expired already
        return ValidationResults(
          isValid: monthValidation.isValidForCurrentYear,
          isPotentiallyValid: monthValidation.isValidForCurrentYear,
          message: yearValidation
              .message, // If year validation failed then this will be set
        );
      }

      // Valid expiration date, all is well
      if (yearValidation.isValid) {
        return ValidationResults(
          isValid: true,
          isPotentiallyValid: true,
        );
      }
    }

    // Still a potentially valid expiration date
    if (monthValidation.isPotentiallyValid &&
        yearValidation.isPotentiallyValid) {
      return ValidationResults(
        isValid: false,
        isPotentiallyValid: true,
      );
    }

    return ValidationResults(
      isValid: false,
      isPotentiallyValid: false,
      message: monthValidation.message,
    );
  }

  ExpYearValidationResults _validateExpYear(String expYearStr,
      [int maxYearsInFuture]) {
    int maxYearsTillExpiration = maxYearsInFuture != null
        ? maxYearsInFuture
        : DEFAULT_NUM_YEARS_IN_FUTURE;

    int fourDigitCurrYear = DateTime.now().year;
    String fourDigitCurrYearStr = fourDigitCurrYear.toString();
    int expYear = int.parse(expYearStr);
    bool isCurrYear = false;

    if (expYearStr.length == 3) {
      // The first 3 digits of a 4 digit year. i.e. 2022, we have the '202'
      // This statement is reached when the user is typing in a full 4 digit year
      int firstTwoDigits = int.parse(expYearStr.substring(0, 2));
      int firstTwoDigitsCurrYear =
          int.parse(fourDigitCurrYearStr.substring(0, 2));
      return ExpYearValidationResults(
        isValid: false,
        isPotentiallyValid: firstTwoDigits == firstTwoDigitsCurrYear,
        expiresThisYear: isCurrYear,
        message: 'Expiration year is 3 digits long',
      );
    }

    if (expYearStr.length > 4) {
      return ExpYearValidationResults(
        isValid: false,
        isPotentiallyValid: false,
        expiresThisYear: isCurrYear,
        message: 'Expiration year is longer than 4 digits',
      );
    }

    bool isValid = false;
    String failedMessage =
        'Expiration year either has passed already or is too far into the future';

    if (expYearStr.length == 2) {
      // Two digit year
      int lastTwoDigitsCurrYear = int.parse(fourDigitCurrYearStr.substring(2));
      isValid = (expYear >= lastTwoDigitsCurrYear &&
          expYear <= lastTwoDigitsCurrYear + maxYearsTillExpiration);
      isCurrYear = expYear == lastTwoDigitsCurrYear;
    } else if (expYearStr.length == 4) {
      // Four digit year
      isValid = (expYear >= fourDigitCurrYear &&
          expYear <= fourDigitCurrYear + maxYearsTillExpiration);
      isCurrYear = expYear == fourDigitCurrYear;
    }

    if (isValid) {
      failedMessage = null;
    }

    return ExpYearValidationResults(
      isValid: isValid,
      isPotentiallyValid: isValid,
      expiresThisYear: isCurrYear,
      message: failedMessage,
    );
  }

  ExpMonthValidationResults _validateExpMonth(String expMonthStr) {
    int currMonth = DateTime.now().month;
    int expMonth = int.parse(expMonthStr);

    bool isValid = expMonth > 0 && expMonth < 13;
    bool isValidForThisYear = isValid && expMonth >= currMonth;

    return ExpMonthValidationResults(
      isValid: isValid,
      isPotentiallyValid: isValid,
      isValidForCurrentYear: isValidForThisYear,
    );
  }

  /// Parses the string form of the expiration date and returns the month and year
  /// as a `List<String>`
  ///
  /// Allows for the following date formats:
  ///     'MM/YY'
  ///     'MM/YYY'
  ///     'MM/YYYY'
  ///
  /// This function will replace hyphens with slashes for dates that have hyphens in them
  /// and remove any whitespace
  List<String> _parseDate(String expDateStr) {
    // Replace hyphens with slashes and remove whitespaces
    String formattedStr = expDateStr.replaceAll('-', '/')
      ..replaceAll(whiteSpaceRegex, '');

    Match match = expDateFormat.firstMatch(formattedStr);
    if (match != null) {
      print("matched! ${match[0]}");
    } else {
      return null;
    }

    List<String> monthAndYear = match[0].split('/');

    return monthAndYear;
  }