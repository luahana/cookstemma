import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';

abstract class AutocompleteRepository {
  Future<Either<Failure, List<AutocompleteResult>>> getAutocomplete(
    String keyword,
    String locale,
  );
}
