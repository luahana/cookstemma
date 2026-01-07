import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import 'package:pairing_planet2_frontend/domain/repositories/autocomplete_repository.dart';

class GetAutocompleteUseCase {
  final AutocompleteRepository _repository;

  GetAutocompleteUseCase(this._repository);

  Future<Either<Failure, List<AutocompleteResult>>> execute(
    String keyword,
    String locale,
  ) async {
    return await _repository.getAutocomplete(keyword, locale);
  }
}
