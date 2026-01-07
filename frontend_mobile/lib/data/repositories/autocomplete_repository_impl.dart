import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/datasources/autocomplete/autocomplete_remote_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import 'package:pairing_planet2_frontend/domain/repositories/autocomplete_repository.dart';

class AutocompleteRepositoryImpl implements AutocompleteRepository {
  final AutocompleteRemoteDataSource _remoteDataSource;

  AutocompleteRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<AutocompleteResult>>> getAutocomplete(
    String keyword,
    String locale,
  ) async {
    try {
      final dtos = await _remoteDataSource.getAutocomplete(keyword, locale);
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
