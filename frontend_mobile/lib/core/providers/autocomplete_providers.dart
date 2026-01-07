import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/repositories/autocomplete_repository_impl.dart';
import '../network/dio_provider.dart';
import '../../data/datasources/autocomplete/autocomplete_remote_data_source.dart';
import '../../domain/repositories/autocomplete_repository.dart';
import '../../domain/usecases/autocomplete/get_autocomplete_usecase.dart';

final autocompleteRemoteDataSourceProvider = Provider(
  (ref) => AutocompleteRemoteDataSource(ref.read(dioProvider)),
);

final autocompleteRepositoryProvider = Provider<AutocompleteRepository>(
  (ref) => AutocompleteRepositoryImpl(
    ref.read(autocompleteRemoteDataSourceProvider),
  ),
);

final getAutocompleteUseCaseProvider = Provider(
  (ref) => GetAutocompleteUseCase(ref.read(autocompleteRepositoryProvider)),
);
