import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/app_database.dart' show SurveysCompanion;
import '../../../../core/database/daos/surveys_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/survey.dart';
import '../../domain/repositories/survey_repository.dart';
import '../datasources/survey_remote_datasource.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  const SurveyRepositoryImpl({
    required this.remote,
    required this.dao,
    required this.connectivity,
  });

  final SurveyRemoteDataSource remote;
  final SurveysDao dao;
  final ConnectivityService connectivity;

  @override
  Future<Either<Failure, List<Survey>>> getAvailableSurveys() async {
    if (!await connectivity.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final server = await remote.fetchSurveys();
      final downloadedIds =
          (await dao.getAllSurveys()).map((s) => s.remoteId).toSet();
      return Right([
        for (final s in server)
          s.copyWith(isDownloaded: downloadedIds.contains(s.remoteId)),
      ]);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> downloadSurvey(String remoteId) async {
    if (!await connectivity.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final detail = await remote.fetchSurvey(remoteId);
      await dao.upsertSurvey(
        SurveysCompanion.insert(
          remoteId: detail.remoteId,
          title: detail.title,
          definitionJson: jsonEncode(detail.definition),
          version: Value(detail.version),
        ),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<Survey>> watchDownloadedSurveys() {
    return dao.watchAllSurveys().map(
          (rows) => [
            for (final r in rows)
              Survey(
                remoteId: r.remoteId,
                title: r.title,
                version: r.version,
                isDownloaded: true,
              ),
          ],
        );
  }
}
