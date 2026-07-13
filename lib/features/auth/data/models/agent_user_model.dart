import '../../domain/entities/agent_user.dart';

/// JSON mapping for [AgentUser]. Kept in the data layer so the domain entity
/// stays free of serialization concerns.
///
/// Used both for the API response and for caching the agent in secure storage
/// (offline profile), so the same shape round-trips in and out of JSON.
class AgentUserModel {
  const AgentUserModel._();

  static AgentUser fromJson(Map<String, dynamic> json) => AgentUser(
        id: json['id'].toString(),
        matricule: json['matricule'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        role: json['role'] as String,
        region: json['region'] as String,
        phone: json['phone'] as String?,
      );

  static Map<String, dynamic> toJson(AgentUser user) => {
        'id': user.id,
        'matricule': user.matricule,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'role': user.role,
        'region': user.region,
        'phone': user.phone,
      };
}
