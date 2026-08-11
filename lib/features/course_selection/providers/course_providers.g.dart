// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courseService)
final courseServiceProvider = CourseServiceProvider._();

final class CourseServiceProvider
    extends $FunctionalProvider<CourseService, CourseService, CourseService>
    with $Provider<CourseService> {
  CourseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseServiceHash();

  @$internal
  @override
  $ProviderElement<CourseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CourseService create(Ref ref) {
    return courseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseService>(value),
    );
  }
}

String _$courseServiceHash() => r'928d49fa20e0b457cb27ee73598458a2123391b7';

@ProviderFor(courses)
final coursesProvider = CoursesProvider._();

final class CoursesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Course>>,
          List<Course>,
          FutureOr<List<Course>>
        >
    with $FutureModifier<List<Course>>, $FutureProvider<List<Course>> {
  CoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coursesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coursesHash();

  @$internal
  @override
  $FutureProviderElement<List<Course>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Course>> create(Ref ref) {
    return courses(ref);
  }
}

String _$coursesHash() => r'd74058bc42eead660b9f7b6e69b1b954494550b6';

@ProviderFor(SelectedCourses)
final selectedCoursesProvider = SelectedCoursesProvider._();

final class SelectedCoursesProvider
    extends $NotifierProvider<SelectedCourses, List<Course>> {
  SelectedCoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCoursesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCoursesHash();

  @$internal
  @override
  SelectedCourses create() => SelectedCourses();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Course> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Course>>(value),
    );
  }
}

String _$selectedCoursesHash() => r'ac8fc31b3a56c57060f923179c11a77b21b3949c';

abstract class _$SelectedCourses extends $Notifier<List<Course>> {
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

@ProviderFor(CourseColors)
final courseColorsProvider = CourseColorsProvider._();

final class CourseColorsProvider
    extends $NotifierProvider<CourseColors, Map<String, Color>> {
  CourseColorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseColorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseColorsHash();

  @$internal
  @override
  CourseColors create() => CourseColors();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Color> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Color>>(value),
    );
  }
}

String _$courseColorsHash() => r'13987a738cc381cc6205896b6503227e5d3e4279';

abstract class _$CourseColors extends $Notifier<Map<String, Color>> {
  Map<String, Color> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, Color>, Map<String, Color>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, Color>, Map<String, Color>>,
              Map<String, Color>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'9c480ca6a5f3f426fcc75a1c7f16250b618c8a84';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AllowConflicts)
final allowConflictsProvider = AllowConflictsProvider._();

final class AllowConflictsProvider
    extends $NotifierProvider<AllowConflicts, bool> {
  AllowConflictsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allowConflictsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allowConflictsHash();

  @$internal
  @override
  AllowConflicts create() => AllowConflicts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$allowConflictsHash() => r'7d07fafe7bc2b4300dd191d74ba01e8a06fbe547';

abstract class _$AllowConflicts extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(MinFreeDays)
final minFreeDaysProvider = MinFreeDaysProvider._();

final class MinFreeDaysProvider extends $NotifierProvider<MinFreeDays, int?> {
  MinFreeDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minFreeDaysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minFreeDaysHash();

  @$internal
  @override
  MinFreeDays create() => MinFreeDays();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$minFreeDaysHash() => r'c2b19313bf5119104c4f786d2af1d7be5bdbf032';

abstract class _$MinFreeDays extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredCourses)
final filteredCoursesProvider = FilteredCoursesProvider._();

final class FilteredCoursesProvider
    extends $FunctionalProvider<List<Course>, List<Course>, List<Course>>
    with $Provider<List<Course>> {
  FilteredCoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredCoursesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredCoursesHash();

  @$internal
  @override
  $ProviderElement<List<Course>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Course> create(Ref ref) {
    return filteredCourses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Course> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Course>>(value),
    );
  }
}

String _$filteredCoursesHash() => r'8de368c1272097f5cc13e1382efd79aefd81b137';

@ProviderFor(SelectedDepartment)
final selectedDepartmentProvider = SelectedDepartmentProvider._();

final class SelectedDepartmentProvider
    extends $NotifierProvider<SelectedDepartment, String?> {
  SelectedDepartmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDepartmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDepartmentHash();

  @$internal
  @override
  SelectedDepartment create() => SelectedDepartment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedDepartmentHash() =>
    r'03add05ba334d906e70e6d4a09185a116f2890d2';

abstract class _$SelectedDepartment extends $Notifier<String?> {
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

@ProviderFor(coursesByDepartment)
final coursesByDepartmentProvider = CoursesByDepartmentProvider._();

final class CoursesByDepartmentProvider
    extends $FunctionalProvider<List<Course>, List<Course>, List<Course>>
    with $Provider<List<Course>> {
  CoursesByDepartmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coursesByDepartmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coursesByDepartmentHash();

  @$internal
  @override
  $ProviderElement<List<Course>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Course> create(Ref ref) {
    return coursesByDepartment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Course> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Course>>(value),
    );
  }
}

String _$coursesByDepartmentHash() =>
    r'7aa6edadd6b379454698d98df431740be62a01ee';

@ProviderFor(ActiveCombinationIndex)
final activeCombinationIndexProvider = ActiveCombinationIndexProvider._();

final class ActiveCombinationIndexProvider
    extends $NotifierProvider<ActiveCombinationIndex, int> {
  ActiveCombinationIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCombinationIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCombinationIndexHash();

  @$internal
  @override
  ActiveCombinationIndex create() => ActiveCombinationIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeCombinationIndexHash() =>
    r'24db3e55c287af6af98aacd084ec703aebba15d2';

abstract class _$ActiveCombinationIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(activeSchedule)
final activeScheduleProvider = ActiveScheduleProvider._();

final class ActiveScheduleProvider
    extends
        $FunctionalProvider<
          Map<String, Map<String, List<Course>>>,
          Map<String, Map<String, List<Course>>>,
          Map<String, Map<String, List<Course>>>
        >
    with $Provider<Map<String, Map<String, List<Course>>>> {
  ActiveScheduleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeScheduleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeScheduleHash();

  @$internal
  @override
  $ProviderElement<Map<String, Map<String, List<Course>>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Map<String, List<Course>>> create(Ref ref) {
    return activeSchedule(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Map<String, List<Course>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, Map<String, List<Course>>>>(value),
    );
  }
}

String _$activeScheduleHash() => r'a74fa17b1473a2a87fa22bb5ef5e988617de9cb8';
