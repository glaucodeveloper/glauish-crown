## stack/utils/semantic.nim
## Base abstraction for semantic domain objects.
## Nim has objects + procs/methods instead of classes; this file gives a class-like
## interface: semanticType, toJson, toPrompt and shortLabel.

import std/[json, strformat]
import ./jsonx

type
  SemanticEntity* = ref object of RootObj
    semanticId*: string
    semanticLabel*: string
    semanticDescription*: string
    metadata*: JsonNode

method semanticType*(entity: SemanticEntity): string {.base.} =
  "SemanticEntity"

method toJson*(entity: SemanticEntity): JsonNode {.base.} =
  result = newJObject()
  result.put("semantic_type", entity.semanticType())
  result.put("id", entity.semanticId)
  result.put("label", entity.semanticLabel)
  result.put("description", entity.semanticDescription)
  result["metadata"] = if entity.metadata.isNil: newJObject() else: entity.metadata

method toPrompt*(entity: SemanticEntity): string {.base.} =
  entity.toJson().pretty()

method shortLabel*(entity: SemanticEntity): string {.base.} =
  if entity.semanticLabel.len > 0:
    entity.semanticLabel
  elif entity.semanticId.len > 0:
    entity.semanticId
  else:
    entity.semanticType()

proc newSemanticEntity*(
  semanticId = "";
  semanticLabel = "";
  semanticDescription = "";
  metadata: JsonNode = newJObject()
): SemanticEntity =
  SemanticEntity(
    semanticId: semanticId,
    semanticLabel: semanticLabel,
    semanticDescription: semanticDescription,
    metadata: metadata
  )

proc semanticHeader*(entity: SemanticEntity): string =
  fmt"{entity.semanticType()}<{entity.shortLabel()}>"
