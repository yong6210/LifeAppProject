import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart' as isar;
import 'package:source_gen/source_gen.dart';

const TypeChecker _collectionChecker = TypeChecker.typeNamed(
  isar.Collection,
  inPackage: 'isar',
);
const TypeChecker _enumeratedChecker = TypeChecker.typeNamed(
  isar.Enumerated,
  inPackage: 'isar',
);
const TypeChecker _embeddedChecker = TypeChecker.typeNamed(
  isar.Embedded,
  inPackage: 'isar',
);
const TypeChecker _ignoreChecker = TypeChecker.typeNamed(
  isar.Ignore,
  inPackage: 'isar',
);
const TypeChecker _nameChecker = TypeChecker.typeNamed(
  isar.Name,
  inPackage: 'isar',
);
const TypeChecker _indexChecker = TypeChecker.typeNamed(
  isar.Index,
  inPackage: 'isar',
);
const TypeChecker _backlinkChecker = TypeChecker.typeNamed(
  isar.Backlink,
  inPackage: 'isar',
);

extension ClassElementX on ClassElement {
  bool get hasZeroArgsConstructor {
    return constructors.any(
      (ConstructorElement c) =>
          c.isPublic && !c.parameters.any((param) => param.isRequired),
    );
  }

  List<PropertyInducingElement> get allAccessors {
    final ignoreFields =
        collectionAnnotation?.ignore ?? embeddedAnnotation!.ignore;
    final inherit =
        collectionAnnotation?.inheritance ?? embeddedAnnotation!.inheritance;

    final candidates = <PropertyInducingElement>[
      ...fields,
      if (inherit)
        for (final supertype in allSupertypes)
          if (!supertype.isDartCoreObject) ...supertype.element.fields,
    ];

    final filtered = candidates.where((element) {
      final name = element.name;
      return element.isPublic &&
          !element.isStatic &&
          !_ignoreChecker.hasAnnotationOf(element.nonSynthetic) &&
          !ignoreFields.contains(name);
    });

    final seen = <String>{};
    return [
      for (final element in filtered)
        if (seen.add(element.name)) element,
    ];
  }

  List<String> get enumConsts {
    return fields
        .where((element) => element.isEnumConstant)
        .map((element) => element.name)
        .whereType<String>()
        .toList();
  }
}

extension PropertyElementX on PropertyInducingElement {
  bool get isLink => type.element?.displayName == 'IsarLink';

  bool get isLinks => type.element?.displayName == 'IsarLinks';

  isar.Enumerated? get enumeratedAnnotation {
    final ann = _enumeratedChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    final typeIndex = ann.getField('type')!.getField('index')!.toIntValue()!;
    return isar.Enumerated(
      isar.EnumType.values[typeIndex],
      ann.getField('property')?.toStringValue(),
    );
  }

  isar.Backlink? get backlinkAnnotation {
    final ann = _backlinkChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return isar.Backlink(to: ann.getField('to')!.toStringValue()!);
  }

  List<isar.Index> get indexAnnotations {
    return _indexChecker.annotationsOfExact(nonSynthetic).map((DartObject ann) {
      final rawComposite = ann.getField('composite')!.toListValue();
      final composite = <isar.CompositeIndex>[];
      if (rawComposite != null) {
        for (final c in rawComposite) {
          final indexTypeField = c.getField('type')!;
          isar.IndexType? indexType;
          if (!indexTypeField.isNull) {
            final indexTypeIndex =
                indexTypeField.getField('index')!.toIntValue()!;
            indexType = isar.IndexType.values[indexTypeIndex];
          }
          composite.add(
            isar.CompositeIndex(
              c.getField('property')!.toStringValue()!,
              type: indexType,
              caseSensitive: c.getField('caseSensitive')!.toBoolValue(),
            ),
          );
        }
      }
      final indexTypeField = ann.getField('type')!;
      isar.IndexType? indexType;
      if (!indexTypeField.isNull) {
        final indexTypeIndex = indexTypeField.getField('index')!.toIntValue()!;
        indexType = isar.IndexType.values[indexTypeIndex];
      }
      return isar.Index(
        name: ann.getField('name')!.toStringValue(),
        composite: composite,
        unique: ann.getField('unique')!.toBoolValue()!,
        replace: ann.getField('replace')!.toBoolValue()!,
        type: indexType,
        caseSensitive: ann.getField('caseSensitive')!.toBoolValue(),
      );
    }).toList();
  }
}

extension ElementX on Element {
  String get isarName {
    final ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    late String name;
    if (ann == null) {
      name = displayName;
    } else {
      name = ann.getField('name')!.toStringValue()!;
    }
    checkIsarName(name, this);
    return name;
  }

  isar.Collection? get collectionAnnotation {
    final ann = _collectionChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return isar.Collection(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      accessor: ann.getField('accessor')!.toStringValue(),
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
    );
  }

  String get collectionAccessor {
    var accessor = collectionAnnotation?.accessor;
    if (accessor != null) {
      return accessor;
    }

    accessor = displayName.decapitalize();
    if (!accessor.endsWith('s')) {
      accessor += 's';
    }

    return accessor;
  }

  isar.Embedded? get embeddedAnnotation {
    final ann = _embeddedChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return isar.Embedded(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
    );
  }
}

void checkIsarName(String name, Element element) {
  if (name.isBlank || name.startsWith('_')) {
    err('Names must not be blank or start with "_".', element);
  }
}

Never err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
