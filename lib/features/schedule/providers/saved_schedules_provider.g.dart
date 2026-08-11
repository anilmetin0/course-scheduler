// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_schedules_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditingScheduleId)
final editingScheduleIdProvider = EditingScheduleIdProvider._();

final class EditingScheduleIdProvider
    extends $NotifierProvider<EditingScheduleId, String?> {
  EditingScheduleIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editingScheduleIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editingScheduleIdHash();

  @$internal
  @override
  EditingScheduleId create() => EditingScheduleId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$editingScheduleIdHash() => r'78b43eeb599023839acfa2f1882c94461e206be0';

abstract class _$EditingScheduleId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveScheduleCourses)
final activeScheduleCoursesProvider = ActiveScheduleCoursesProvider._();

final class ActiveScheduleCoursesProvider
    extends $NotifierProvider<ActiveScheduleCourses, List<Course>> {
  ActiveScheduleCoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeScheduleCoursesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeScheduleCoursesHash();

  @$internal
  @override
  ActiveScheduleCourses create() => ActiveScheduleCourses();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Course> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Course>>(value),
    );
  }
}

String _$activeScheduleCoursesHash() =>
    r'95cc77d8be26e463dea9d9e38f0e69e199156a44';

abstract class _$ActiveScheduleCourses extends $Notifier<List<Course>> {
  List<Course> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Course>, List<Course>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Course>, List<Course>>,
              List<Course>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SavedSchedules)
final savedSchedulesProvider = SavedSchedulesProvider._();

final class SavedSchedulesProvider
    extends $NotifierProvider<SavedSchedules, List<SavedSchedule>> {
  SavedSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedSchedulesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedSchedulesHash();

  @$internal
  @override
  SavedSchedules create() => SavedSchedules();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SavedSchedule> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SavedSchedule>>(value),
    );
  }
}

String _$savedSchedulesHash() => r'83e35bc335e07da602bb04a91c20b28c06945f57';

abstract class _$SavedSchedules extends $Notifier<List<SavedSchedule>> {
  List<SavedSchedule> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<SavedSchedule>, List<SavedSchedule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SavedSchedule>, List<SavedSchedule>>,
              List<SavedSchedule>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
