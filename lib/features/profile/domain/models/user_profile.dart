class ProfilePlace {
  const ProfilePlace({
    required this.slug,
    required this.name,
    this.location = '',
    this.imageUrl,
  });

  final String slug;
  final String name;
  final String location;
  final String? imageUrl;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.visitedPlaceCount = 0,
    this.savedPlaceCount = 0,
    this.plannedTripCount = 0,
    this.recentPlaces = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final int visitedPlaceCount;
  final int savedPlaceCount;
  final int plannedTripCount;
  final List<ProfilePlace> recentPlaces;

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    int? visitedPlaceCount,
    int? savedPlaceCount,
    int? plannedTripCount,
    List<ProfilePlace>? recentPlaces,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      visitedPlaceCount: visitedPlaceCount ?? this.visitedPlaceCount,
      savedPlaceCount: savedPlaceCount ?? this.savedPlaceCount,
      plannedTripCount: plannedTripCount ?? this.plannedTripCount,
      recentPlaces: recentPlaces ?? this.recentPlaces,
    );
  }
}
