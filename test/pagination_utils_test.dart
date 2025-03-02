import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/models/response/links_model.dart';
import 'package:dio_flow/src/models/response/meta_model.dart';

void main() {
  group('PaginationUtils - hasMorePages', () {
    test('should return false for failed responses', () {
      final failedResponse = FailedResponseModel(
        statusCode: 400,
        message: 'Bad request',
        logCurl: 'curl example.com',
        errorType: ErrorType.validation,
      );

      expect(PaginationUtils.hasMorePages(failedResponse, 10), isFalse);
    });

    test('should return true when links.next is available', () {
      final links = LinksModel(
        first: 'https://api.example.com/posts?page=1',
        last: 'https://api.example.com/posts?page=5',
        prev: null,
        next: 'https://api.example.com/posts?page=2',
      );

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        links: links,
      );

      expect(PaginationUtils.hasMorePages(response, 10), isTrue);
    });

    test('should return false when links.next is null', () {
      final links = LinksModel(
        first: 'https://api.example.com/posts?page=1',
        last: 'https://api.example.com/posts?page=1',
        prev: null,
        next: null,
      );

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(5, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        links: links,
      );

      expect(PaginationUtils.hasMorePages(response, 5), isFalse);
    });

    test('should return true when currentPage < lastPage', () {
      final meta = MetaModel(
        currentPage: 1,
        lastPage: 5,
        perPage: 10,
        total: 50,
      );

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        meta: meta,
      );

      expect(PaginationUtils.hasMorePages(response, 10), isTrue);
    });

    test('should return false when currentPage = lastPage', () {
      final meta = MetaModel(
        currentPage: 5,
        lastPage: 5,
        perPage: 10,
        total: 50,
      );

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        meta: meta,
      );

      expect(PaginationUtils.hasMorePages(response, 10), isFalse);
    });

    test('should return true when not all items are fetched', () {
      final meta = MetaModel(currentPage: 1, perPage: 10, total: 50);

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        meta: meta,
      );

      expect(PaginationUtils.hasMorePages(response, 10), isTrue);
    });

    test('should return false when all items are fetched', () {
      final meta = MetaModel(currentPage: 5, perPage: 10, total: 50);

      final response = SuccessResponseModel(
        statusCode: 200,
        data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
        logCurl: 'curl example.com',
        meta: meta,
      );

      // 5 pages * 10 items = 50 items, which is equal to total
      expect(PaginationUtils.hasMorePages(response, 10), isFalse);
    });

    test(
      'should fallback to checking current page items when no meta or links',
      () {
        final response = SuccessResponseModel(
          statusCode: 200,
          data: List.generate(10, (i) => {'id': i, 'title': 'Post $i'}),
          logCurl: 'curl example.com',
        );

        // Default page size assumption is 10, so should assume more pages exist
        expect(PaginationUtils.hasMorePages(response, 10), isTrue);

        // When less than default page size, should assume no more pages
        expect(PaginationUtils.hasMorePages(response, 5), isFalse);
      },
    );
  });

  // Mock tests for fetchAllPages would require setting up a mock for DioRequestHandler,
  // which is beyond the scope of this basic test file. In a real project, you would use
  // a package like mockito to mock the network calls.
}
