import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef CountryLoader = Future<List<String>> Function();

const String apiKey = String.fromEnvironment('REST_COUNTRIES_API_KEY');

class CountryService {
  CountryService({http.Client? client, String apiKeyOverride = apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKeyOverride;

  static final Uri endpoint = Uri.parse(
    'https://api.restcountries.com/countries/v5',
  );
  static const int _pageSize = 100;

  final http.Client _client;
  final String _apiKey;

  Future<List<String>> fetchCountries() async {
    if (_apiKey.trim().isEmpty) {
      throw const CountryServiceException(
        'Unable to load countries: REST_COUNTRIES_API_KEY is not configured.',
      );
    }

    try {
      final uniqueNames = <String>{};
      var offset = 0;
      var hasMore = true;

      while (hasMore) {
        final pageUri = endpoint.replace(
          queryParameters: {
            'response_fields': 'names.common',
            'limit': '$_pageSize',
            'offset': '$offset',
          },
        );
        final response = await _client
            .get(pageUri, headers: {'Authorization': 'Bearer $_apiKey'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw CountryServiceException(
            'Unable to load countries (HTTP ${response.statusCode}).',
          );
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) {
          throw const CountryServiceException(
            'Unable to load countries: invalid response format.',
          );
        }
        final data = decoded['data'];
        if (data is! Map) {
          throw const CountryServiceException(
            'Unable to load countries: missing response data.',
          );
        }
        final objects = data['objects'];
        final meta = data['meta'];
        if (objects is! List || meta is! Map || meta['more'] is! bool) {
          throw const CountryServiceException(
            'Unable to load countries: invalid paginated response.',
          );
        }

        for (final country in objects) {
          if (country is! Map) continue;
          final names = country['names'];
          if (names is! Map) continue;
          final commonName = names['common'];
          if (commonName is! String) continue;
          final trimmedName = commonName.trim();
          if (trimmedName.isNotEmpty) uniqueNames.add(trimmedName);
        }

        hasMore = meta['more'] as bool;
        if (hasMore && objects.isEmpty) {
          throw const CountryServiceException(
            'Unable to load countries: invalid pagination state.',
          );
        }
        offset += objects.length;
      }

      final countries = uniqueNames.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (countries.isEmpty) {
        throw const CountryServiceException(
          'Unable to load countries: no valid names found.',
        );
      }
      return countries;
    } on CountryServiceException {
      rethrow;
    } on TimeoutException {
      throw const CountryServiceException(
        'Unable to load countries: request timed out.',
      );
    } on FormatException {
      throw const CountryServiceException(
        'Unable to load countries: invalid JSON response.',
      );
    } catch (error) {
      throw CountryServiceException(
        'Unable to load countries: ${error.runtimeType}.',
      );
    }
  }
}

class CountryServiceException implements Exception {
  const CountryServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
