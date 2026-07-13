// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurveysTable extends Surveys with TableInfo<$SurveysTable, Survey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _definitionJsonMeta =
      const VerificationMeta('definitionJson');
  @override
  late final GeneratedColumn<String> definitionJson = GeneratedColumn<String>(
      'definition_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [remoteId, title, version, definitionJson, downloadedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surveys';
  @override
  VerificationContext validateIntegrity(Insertable<Survey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('definition_json')) {
      context.handle(
          _definitionJsonMeta,
          definitionJson.isAcceptableOrUnknown(
              data['definition_json']!, _definitionJsonMeta));
    } else if (isInserting) {
      context.missing(_definitionJsonMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteId};
  @override
  Survey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Survey(
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      definitionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}definition_json'])!,
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $SurveysTable createAlias(String alias) {
    return $SurveysTable(attachedDatabase, alias);
  }
}

class Survey extends DataClass implements Insertable<Survey> {
  /// Server-side identifier (e.g. "survey_household_2026"). Primary key so a
  /// re-download of the same survey upserts rather than duplicates.
  final String remoteId;
  final String title;
  final int version;

  /// The full, untouched survey JSON (pages, questions, options, validation).
  final String definitionJson;
  final DateTime downloadedAt;
  const Survey(
      {required this.remoteId,
      required this.title,
      required this.version,
      required this.definitionJson,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_id'] = Variable<String>(remoteId);
    map['title'] = Variable<String>(title);
    map['version'] = Variable<int>(version);
    map['definition_json'] = Variable<String>(definitionJson);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  SurveysCompanion toCompanion(bool nullToAbsent) {
    return SurveysCompanion(
      remoteId: Value(remoteId),
      title: Value(title),
      version: Value(version),
      definitionJson: Value(definitionJson),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory Survey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Survey(
      remoteId: serializer.fromJson<String>(json['remoteId']),
      title: serializer.fromJson<String>(json['title']),
      version: serializer.fromJson<int>(json['version']),
      definitionJson: serializer.fromJson<String>(json['definitionJson']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteId': serializer.toJson<String>(remoteId),
      'title': serializer.toJson<String>(title),
      'version': serializer.toJson<int>(version),
      'definitionJson': serializer.toJson<String>(definitionJson),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  Survey copyWith(
          {String? remoteId,
          String? title,
          int? version,
          String? definitionJson,
          DateTime? downloadedAt}) =>
      Survey(
        remoteId: remoteId ?? this.remoteId,
        title: title ?? this.title,
        version: version ?? this.version,
        definitionJson: definitionJson ?? this.definitionJson,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  Survey copyWithCompanion(SurveysCompanion data) {
    return Survey(
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      title: data.title.present ? data.title.value : this.title,
      version: data.version.present ? data.version.value : this.version,
      definitionJson: data.definitionJson.present
          ? data.definitionJson.value
          : this.definitionJson,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Survey(')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('version: $version, ')
          ..write('definitionJson: $definitionJson, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(remoteId, title, version, definitionJson, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Survey &&
          other.remoteId == this.remoteId &&
          other.title == this.title &&
          other.version == this.version &&
          other.definitionJson == this.definitionJson &&
          other.downloadedAt == this.downloadedAt);
}

class SurveysCompanion extends UpdateCompanion<Survey> {
  final Value<String> remoteId;
  final Value<String> title;
  final Value<int> version;
  final Value<String> definitionJson;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const SurveysCompanion({
    this.remoteId = const Value.absent(),
    this.title = const Value.absent(),
    this.version = const Value.absent(),
    this.definitionJson = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveysCompanion.insert({
    required String remoteId,
    required String title,
    this.version = const Value.absent(),
    required String definitionJson,
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : remoteId = Value(remoteId),
        title = Value(title),
        definitionJson = Value(definitionJson);
  static Insertable<Survey> custom({
    Expression<String>? remoteId,
    Expression<String>? title,
    Expression<int>? version,
    Expression<String>? definitionJson,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteId != null) 'remote_id': remoteId,
      if (title != null) 'title': title,
      if (version != null) 'version': version,
      if (definitionJson != null) 'definition_json': definitionJson,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveysCompanion copyWith(
      {Value<String>? remoteId,
      Value<String>? title,
      Value<int>? version,
      Value<String>? definitionJson,
      Value<DateTime>? downloadedAt,
      Value<int>? rowid}) {
    return SurveysCompanion(
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      version: version ?? this.version,
      definitionJson: definitionJson ?? this.definitionJson,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (definitionJson.present) {
      map['definition_json'] = Variable<String>(definitionJson.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveysCompanion(')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('version: $version, ')
          ..write('definitionJson: $definitionJson, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyResponsesTable extends SurveyResponses
    with TableInfo<$SurveyResponsesTable, SurveyResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyRemoteIdMeta =
      const VerificationMeta('surveyRemoteId');
  @override
  late final GeneratedColumn<String> surveyRemoteId = GeneratedColumn<String>(
      'survey_remote_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentIdMeta =
      const VerificationMeta('agentId');
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
      'agent_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answersJsonMeta =
      const VerificationMeta('answersJson');
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
      'answers_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>('sync_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<SyncStatus>(
              $SurveyResponsesTable.$convertersyncStatus);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyRemoteId,
        agentId,
        answersJson,
        syncStatus,
        attempts,
        lastError,
        remoteId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_responses';
  @override
  VerificationContext validateIntegrity(Insertable<SurveyResponse> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_remote_id')) {
      context.handle(
          _surveyRemoteIdMeta,
          surveyRemoteId.isAcceptableOrUnknown(
              data['survey_remote_id']!, _surveyRemoteIdMeta));
    } else if (isInserting) {
      context.missing(_surveyRemoteIdMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(_agentIdMeta,
          agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta));
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('answers_json')) {
      context.handle(
          _answersJsonMeta,
          answersJson.isAcceptableOrUnknown(
              data['answers_json']!, _answersJsonMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyResponse(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyRemoteId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}survey_remote_id'])!,
      agentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_id'])!,
      answersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers_json'])!,
      syncStatus: $SurveyResponsesTable.$convertersyncStatus.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SurveyResponsesTable createAlias(String alias) {
    return $SurveyResponsesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class SurveyResponse extends DataClass implements Insertable<SurveyResponse> {
  /// Client-generated UUID — assigned offline so a response has a stable
  /// identity before it ever reaches the server.
  final String id;

  /// FK to [Surveys.remoteId] — which survey this response answers.
  final String surveyRemoteId;

  /// The agent who collected it (for multi-user devices / audit).
  final String agentId;

  /// `{ "q_region": "marrakech_safi", "q_household_size": 4, ... }`
  final String answersJson;

  /// Persisted as its integer index — see [SyncStatus] append-only warning.
  final SyncStatus syncStatus;
  final int attempts;
  final String? lastError;

  /// Server id, populated after a successful upload (null while offline).
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SurveyResponse(
      {required this.id,
      required this.surveyRemoteId,
      required this.agentId,
      required this.answersJson,
      required this.syncStatus,
      required this.attempts,
      this.lastError,
      this.remoteId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_remote_id'] = Variable<String>(surveyRemoteId);
    map['agent_id'] = Variable<String>(agentId);
    map['answers_json'] = Variable<String>(answersJson);
    {
      map['sync_status'] = Variable<int>(
          $SurveyResponsesTable.$convertersyncStatus.toSql(syncStatus));
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SurveyResponsesCompanion toCompanion(bool nullToAbsent) {
    return SurveyResponsesCompanion(
      id: Value(id),
      surveyRemoteId: Value(surveyRemoteId),
      agentId: Value(agentId),
      answersJson: Value(answersJson),
      syncStatus: Value(syncStatus),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SurveyResponse.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyResponse(
      id: serializer.fromJson<String>(json['id']),
      surveyRemoteId: serializer.fromJson<String>(json['surveyRemoteId']),
      agentId: serializer.fromJson<String>(json['agentId']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      syncStatus: $SurveyResponsesTable.$convertersyncStatus
          .fromJson(serializer.fromJson<int>(json['syncStatus'])),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyRemoteId': serializer.toJson<String>(surveyRemoteId),
      'agentId': serializer.toJson<String>(agentId),
      'answersJson': serializer.toJson<String>(answersJson),
      'syncStatus': serializer.toJson<int>(
          $SurveyResponsesTable.$convertersyncStatus.toJson(syncStatus)),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SurveyResponse copyWith(
          {String? id,
          String? surveyRemoteId,
          String? agentId,
          String? answersJson,
          SyncStatus? syncStatus,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          Value<String?> remoteId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SurveyResponse(
        id: id ?? this.id,
        surveyRemoteId: surveyRemoteId ?? this.surveyRemoteId,
        agentId: agentId ?? this.agentId,
        answersJson: answersJson ?? this.answersJson,
        syncStatus: syncStatus ?? this.syncStatus,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SurveyResponse copyWithCompanion(SurveyResponsesCompanion data) {
    return SurveyResponse(
      id: data.id.present ? data.id.value : this.id,
      surveyRemoteId: data.surveyRemoteId.present
          ? data.surveyRemoteId.value
          : this.surveyRemoteId,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      answersJson:
          data.answersJson.present ? data.answersJson.value : this.answersJson,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyResponse(')
          ..write('id: $id, ')
          ..write('surveyRemoteId: $surveyRemoteId, ')
          ..write('agentId: $agentId, ')
          ..write('answersJson: $answersJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surveyRemoteId, agentId, answersJson,
      syncStatus, attempts, lastError, remoteId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyResponse &&
          other.id == this.id &&
          other.surveyRemoteId == this.surveyRemoteId &&
          other.agentId == this.agentId &&
          other.answersJson == this.answersJson &&
          other.syncStatus == this.syncStatus &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SurveyResponsesCompanion extends UpdateCompanion<SurveyResponse> {
  final Value<String> id;
  final Value<String> surveyRemoteId;
  final Value<String> agentId;
  final Value<String> answersJson;
  final Value<SyncStatus> syncStatus;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SurveyResponsesCompanion({
    this.id = const Value.absent(),
    this.surveyRemoteId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyResponsesCompanion.insert({
    required String id,
    required String surveyRemoteId,
    required String agentId,
    this.answersJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyRemoteId = Value(surveyRemoteId),
        agentId = Value(agentId);
  static Insertable<SurveyResponse> custom({
    Expression<String>? id,
    Expression<String>? surveyRemoteId,
    Expression<String>? agentId,
    Expression<String>? answersJson,
    Expression<int>? syncStatus,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyRemoteId != null) 'survey_remote_id': surveyRemoteId,
      if (agentId != null) 'agent_id': agentId,
      if (answersJson != null) 'answers_json': answersJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyResponsesCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyRemoteId,
      Value<String>? agentId,
      Value<String>? answersJson,
      Value<SyncStatus>? syncStatus,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<String?>? remoteId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SurveyResponsesCompanion(
      id: id ?? this.id,
      surveyRemoteId: surveyRemoteId ?? this.surveyRemoteId,
      agentId: agentId ?? this.agentId,
      answersJson: answersJson ?? this.answersJson,
      syncStatus: syncStatus ?? this.syncStatus,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyRemoteId.present) {
      map['survey_remote_id'] = Variable<String>(surveyRemoteId.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
          $SurveyResponsesTable.$convertersyncStatus.toSql(syncStatus.value));
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyResponsesCompanion(')
          ..write('id: $id, ')
          ..write('surveyRemoteId: $surveyRemoteId, ')
          ..write('agentId: $agentId, ')
          ..write('answersJson: $answersJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurveysTable surveys = $SurveysTable(this);
  late final $SurveyResponsesTable surveyResponses =
      $SurveyResponsesTable(this);
  late final SurveysDao surveysDao = SurveysDao(this as AppDatabase);
  late final ResponsesDao responsesDao = ResponsesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [surveys, surveyResponses];
}

typedef $$SurveysTableCreateCompanionBuilder = SurveysCompanion Function({
  required String remoteId,
  required String title,
  Value<int> version,
  required String definitionJson,
  Value<DateTime> downloadedAt,
  Value<int> rowid,
});
typedef $$SurveysTableUpdateCompanionBuilder = SurveysCompanion Function({
  Value<String> remoteId,
  Value<String> title,
  Value<int> version,
  Value<String> definitionJson,
  Value<DateTime> downloadedAt,
  Value<int> rowid,
});

class $$SurveysTableFilterComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get definitionJson => $composableBuilder(
      column: $table.definitionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$SurveysTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get definitionJson => $composableBuilder(
      column: $table.definitionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SurveysTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get definitionJson => $composableBuilder(
      column: $table.definitionJson, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$SurveysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveysTable,
    Survey,
    $$SurveysTableFilterComposer,
    $$SurveysTableOrderingComposer,
    $$SurveysTableAnnotationComposer,
    $$SurveysTableCreateCompanionBuilder,
    $$SurveysTableUpdateCompanionBuilder,
    (Survey, BaseReferences<_$AppDatabase, $SurveysTable, Survey>),
    Survey,
    PrefetchHooks Function()> {
  $$SurveysTableTableManager(_$AppDatabase db, $SurveysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> remoteId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String> definitionJson = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveysCompanion(
            remoteId: remoteId,
            title: title,
            version: version,
            definitionJson: definitionJson,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String remoteId,
            required String title,
            Value<int> version = const Value.absent(),
            required String definitionJson,
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveysCompanion.insert(
            remoteId: remoteId,
            title: title,
            version: version,
            definitionJson: definitionJson,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveysTable,
    Survey,
    $$SurveysTableFilterComposer,
    $$SurveysTableOrderingComposer,
    $$SurveysTableAnnotationComposer,
    $$SurveysTableCreateCompanionBuilder,
    $$SurveysTableUpdateCompanionBuilder,
    (Survey, BaseReferences<_$AppDatabase, $SurveysTable, Survey>),
    Survey,
    PrefetchHooks Function()>;
typedef $$SurveyResponsesTableCreateCompanionBuilder = SurveyResponsesCompanion
    Function({
  required String id,
  required String surveyRemoteId,
  required String agentId,
  Value<String> answersJson,
  Value<SyncStatus> syncStatus,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String?> remoteId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SurveyResponsesTableUpdateCompanionBuilder = SurveyResponsesCompanion
    Function({
  Value<String> id,
  Value<String> surveyRemoteId,
  Value<String> agentId,
  Value<String> answersJson,
  Value<SyncStatus> syncStatus,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String?> remoteId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SurveyResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTable> {
  $$SurveyResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyRemoteId => $composableBuilder(
      column: $table.surveyRemoteId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentId => $composableBuilder(
      column: $table.agentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SurveyResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTable> {
  $$SurveyResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyRemoteId => $composableBuilder(
      column: $table.surveyRemoteId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentId => $composableBuilder(
      column: $table.agentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SurveyResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTable> {
  $$SurveyResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyRemoteId => $composableBuilder(
      column: $table.surveyRemoteId, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SurveyResponsesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveyResponsesTable,
    SurveyResponse,
    $$SurveyResponsesTableFilterComposer,
    $$SurveyResponsesTableOrderingComposer,
    $$SurveyResponsesTableAnnotationComposer,
    $$SurveyResponsesTableCreateCompanionBuilder,
    $$SurveyResponsesTableUpdateCompanionBuilder,
    (
      SurveyResponse,
      BaseReferences<_$AppDatabase, $SurveyResponsesTable, SurveyResponse>
    ),
    SurveyResponse,
    PrefetchHooks Function()> {
  $$SurveyResponsesTableTableManager(
      _$AppDatabase db, $SurveyResponsesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyResponsesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyRemoteId = const Value.absent(),
            Value<String> agentId = const Value.absent(),
            Value<String> answersJson = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyResponsesCompanion(
            id: id,
            surveyRemoteId: surveyRemoteId,
            agentId: agentId,
            answersJson: answersJson,
            syncStatus: syncStatus,
            attempts: attempts,
            lastError: lastError,
            remoteId: remoteId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyRemoteId,
            required String agentId,
            Value<String> answersJson = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyResponsesCompanion.insert(
            id: id,
            surveyRemoteId: surveyRemoteId,
            agentId: agentId,
            answersJson: answersJson,
            syncStatus: syncStatus,
            attempts: attempts,
            lastError: lastError,
            remoteId: remoteId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveyResponsesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveyResponsesTable,
    SurveyResponse,
    $$SurveyResponsesTableFilterComposer,
    $$SurveyResponsesTableOrderingComposer,
    $$SurveyResponsesTableAnnotationComposer,
    $$SurveyResponsesTableCreateCompanionBuilder,
    $$SurveyResponsesTableUpdateCompanionBuilder,
    (
      SurveyResponse,
      BaseReferences<_$AppDatabase, $SurveyResponsesTable, SurveyResponse>
    ),
    SurveyResponse,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurveysTableTableManager get surveys =>
      $$SurveysTableTableManager(_db, _db.surveys);
  $$SurveyResponsesTableTableManager get surveyResponses =>
      $$SurveyResponsesTableTableManager(_db, _db.surveyResponses);
}
