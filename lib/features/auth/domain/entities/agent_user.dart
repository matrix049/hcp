/// The authenticated **HCP survey agent** — the only kind of app user.
///
/// The respondent (citizen) is NOT modelled here; their information belongs to
/// survey responses, not to this entity.
///
/// Pure domain object: no JSON, no Flutter, no persistence concerns. Mapping to
/// and from JSON lives in the data layer (`AgentUserModel`).
class AgentUser {
  const AgentUser({
    required this.id,
    required this.matricule,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.region,
    this.phone,
  });

  final String id;
  final String matricule;
  final String firstName;
  final String lastName;
  final String role;
  final String region;
  final String? phone;

  String get fullName => '$firstName $lastName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentUser &&
          other.id == id &&
          other.matricule == matricule &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.role == role &&
          other.region == region &&
          other.phone == phone;

  @override
  int get hashCode =>
      Object.hash(id, matricule, firstName, lastName, role, region, phone);
}
