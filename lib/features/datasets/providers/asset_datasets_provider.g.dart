// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_datasets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(assetDatasets)
final assetDatasetsProvider = AssetDatasetsProvider._();

final class AssetDatasetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AssetDatasetMeta>>,
          List<AssetDatasetMeta>,
          FutureOr<List<AssetDatasetMeta>>
        >
    with
        $FutureModifier<List<AssetDatasetMeta>>,
        $FutureProvider<List<AssetDatasetMeta>> {
  AssetDatasetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetDatasetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetDatasetsHash();

  @$internal
  @override
  $FutureProviderElement<List<AssetDatasetMeta>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AssetDatasetMeta>> create(Ref ref) {
    return assetDatasets(ref);
  }
}

String _$assetDatasetsHash() => r'9b0c1d4e65646d545da65ae12ac6218fb45e237e';

@ProviderFor(ActiveAssetDatasetPath)
final activeAssetDatasetPathProvider = ActiveAssetDatasetPathProvider._();

final class ActiveAssetDatasetPathProvider
    extends $NotifierProvider<ActiveAssetDatasetPath, String> {
  ActiveAssetDatasetPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAssetDatasetPathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAssetDatasetPathHash();

  @$internal
  @override
  ActiveAssetDatasetPath create() => ActiveAssetDatasetPath();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$activeAssetDatasetPathHash() =>
    r'7adb5ef2e5c8e33bfc1f9c2bd0c85302745a5173';

abstract class _$ActiveAssetDatasetPath extends $Notifier<String> {
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

@ProviderFor(currentDatasetInfo)
final currentDatasetInfoProvider = CurrentDatasetInfoProvider._();

final class CurrentDatasetInfoProvider
    extends
        $FunctionalProvider<
          AssetDatasetMeta?,
          AssetDatasetMeta?,
          AssetDatasetMeta?
        >
    with $Provider<AssetDatasetMeta?> {
  CurrentDatasetInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDatasetInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDatasetInfoHash();

  @$internal
  @override
  $ProviderElement<AssetDatasetMeta?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AssetDatasetMeta? create(Ref ref) {
    return currentDatasetInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetDatasetMeta? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetDatasetMeta?>(value),
    );
  }
}

String _$currentDatasetInfoHash() =>
    r'dbeb6f4227888d987fea798ae92ec6102cb8d9ad';

@ProviderFor(mostRecentDatasetPath)
final mostRecentDatasetPathProvider = MostRecentDatasetPathProvider._();

final class MostRecentDatasetPathProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  MostRecentDatasetPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mostRecentDatasetPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mostRecentDatasetPathHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return mostRecentDatasetPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$mostRecentDatasetPathHash() =>
    r'2d4c22a4ed6a92cb29dfdef9a66c9e9d17098509';

@ProviderFor(SelectedAssetCompare)
final selectedAssetCompareProvider = SelectedAssetCompareProvider._();

final class SelectedAssetCompareProvider
    extends $NotifierProvider<SelectedAssetCompare, Set<String>> {
  SelectedAssetCompareProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAssetCompareProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAssetCompareHash();

  @$internal
  @override
  SelectedAssetCompare create() => SelectedAssetCompare();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedAssetCompareHash() =>
    r'47beb9a040ff75dfcf405de4214fcb4b3111581f';

abstract class _$SelectedAssetCompare extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(newerDatasetAvailable)
final newerDatasetAvailableProvider = NewerDatasetAvailableProvider._();

final class NewerDatasetAvailableProvider
    extends
        $FunctionalProvider<
          NewerDatasetInfo?,
          NewerDatasetInfo?,
          NewerDatasetInfo?
        >
    with $Provider<NewerDatasetInfo?> {
  NewerDatasetAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newerDatasetAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newerDatasetAvailableHash();

  @$internal
  @override
  $ProviderElement<NewerDatasetInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NewerDatasetInfo? create(Ref ref) {
    return newerDatasetAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewerDatasetInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewerDatasetInfo?>(value),
    );
  }
}

String _$newerDatasetAvailableHash() =>
    r'f7188395724414b118057048c3b8b0a1ad4853c5';

@ProviderFor(NewerDatasetDismissed)
final newerDatasetDismissedProvider = NewerDatasetDismissedProvider._();

final class NewerDatasetDismissedProvider
    extends $NotifierProvider<NewerDatasetDismissed, String?> {
  NewerDatasetDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newerDatasetDismissedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newerDatasetDismissedHash();

  @$internal
  @override
  NewerDatasetDismissed create() => NewerDatasetDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$newerDatasetDismissedHash() =>
    r'6b2ecaf674f6bf46b9d3c019441003d89169fb11';

abstract class _$NewerDatasetDismissed extends $Notifier<String?> {
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

@ProviderFor(assetDatasetCourses)
final assetDatasetCoursesProvider = AssetDatasetCoursesFamily._();

final class AssetDatasetCoursesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  AssetDatasetCoursesProvider._({
    required AssetDatasetCoursesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'assetDatasetCoursesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$assetDatasetCoursesHash();

  @override
  String toString() {
    return r'assetDatasetCoursesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return assetDatasetCourses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AssetDatasetCoursesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$assetDatasetCoursesHash() =>
    r'9d29d779d57c6a62fb1ecca3008d00092f1d023d';

final class AssetDatasetCoursesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  AssetDatasetCoursesFamily._()
    : super(
        retry: null,
        name: r'assetDatasetCoursesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AssetDatasetCoursesProvider call(String path) =>
      AssetDatasetCoursesProvider._(argument: path, from: this);

  @override
  String toString() => r'assetDatasetCoursesProvider';
}
