## stack/utils/bncc_semantics.nim
## BNCC semantic classes.
##
## Domain entities live here, not in main.nim.
## They are class-like semantic objects: properties + constructors + methods.

import std/[json]
import ./jsonx
import ./classx

Class BnccSkill:
  codigo*: string
  etapa*: string
  serieBase*: string
  blocoBncc*: string
  componente*: string
  area*: string
  campo*: string
  praticaLinguagem*: string
  objetoConhecimento*: string
  habilidade*: string
  fontePdfPagina*: int

Class SkillComprehensions:
  bnccContext*: string
  textBase*: string
  textBaseInternalAnalysis*: string
  questionTopic*: string
  rewriteReport*: string

Class SkillConfig:
  skill*: BnccSkill
  comprehensions*: SkillComprehensions

Class StudentProfile:
  nome*: string
  etapa*: string
  serie*: string
  faixaEtaria*: string
  fase*: string
  funcionamento*: seq[string]
  necessidades*: seq[string]
  evidenciasDesejadas*: seq[string]

proc newBnccSkill*(
  codigo, etapa, serieBase, blocoBncc, componente, area, campo,
  praticaLinguagem, objetoConhecimento, habilidade: string;
  fontePdfPagina: int
): BnccSkill =
  BnccSkill(
    semanticId: codigo,
    semanticLabel: codigo & " - " & componente,
    semanticDescription: habilidade,
    metadata: newJObject(),
    codigo: codigo,
    etapa: etapa,
    serieBase: serieBase,
    blocoBncc: blocoBncc,
    componente: componente,
    area: area,
    campo: campo,
    praticaLinguagem: praticaLinguagem,
    objetoConhecimento: objetoConhecimento,
    habilidade: habilidade,
    fontePdfPagina: fontePdfPagina
  )

proc newSkillComprehensions*(
  bnccContext, textBase, textBaseInternalAnalysis, questionTopic, rewriteReport: string
): SkillComprehensions =
  SkillComprehensions(
    semanticId: "skill_comprehensions",
    semanticLabel: "Compreensões da habilidade",
    semanticDescription: "Compreensões operacionais para geração e avaliação BNCC.",
    metadata: newJObject(),
    bnccContext: bnccContext,
    textBase: textBase,
    textBaseInternalAnalysis: textBaseInternalAnalysis,
    questionTopic: questionTopic,
    rewriteReport: rewriteReport
  )

proc newSkillConfig*(skill: BnccSkill; comprehensions: SkillComprehensions): SkillConfig =
  SkillConfig(
    semanticId: skill.codigo,
    semanticLabel: "Configuração " & skill.codigo,
    semanticDescription: "Recorte BNCC + compreensões aplicadas.",
    metadata: newJObject(),
    skill: skill,
    comprehensions: comprehensions
  )

proc newStudentProfile*(
  id, nome, etapa, serie, faixaEtaria, fase: string;
  funcionamento, necessidades, evidenciasDesejadas: seq[string]
): StudentProfile =
  StudentProfile(
    semanticId: id,
    semanticLabel: nome,
    semanticDescription: etapa & " / " & serie,
    metadata: newJObject(),
    nome: nome,
    etapa: etapa,
    serie: serie,
    faixaEtaria: faixaEtaria,
    fase: fase,
    funcionamento: funcionamento,
    necessidades: necessidades,
    evidenciasDesejadas: evidenciasDesejadas
  )

method shortLabel*(skill: BnccSkill): string =
  skill.codigo & " / " & skill.componente

method shortLabel*(cfg: SkillConfig): string =
  cfg.skill.shortLabel()

method shortLabel*(profile: StudentProfile): string =
  profile.nome & " / " & profile.serie

method toJson*(skill: BnccSkill): JsonNode =
  result = newJObject()
  result.put("semantic_type", skill.semanticType())
  result.put("codigo", skill.codigo)
  result.put("etapa", skill.etapa)
  result.put("serie_base", skill.serieBase)
  result.put("bloco_bncc", skill.blocoBncc)
  result.put("componente", skill.componente)
  result.put("area", skill.area)
  result.put("campo", skill.campo)
  result.put("pratica_linguagem", skill.praticaLinguagem)
  result.put("objeto_conhecimento", skill.objetoConhecimento)
  result.put("habilidade", skill.habilidade)
  result.put("fonte_pdf_pagina", skill.fontePdfPagina)

method toJson*(c: SkillComprehensions): JsonNode =
  result = newJObject()
  result.put("semantic_type", c.semanticType())
  result.put("bncc_context_comprehension", c.bnccContext)
  result.put("text_base_comprehension", c.textBase)
  result.put("text_base_internal_analysis_comprehension", c.textBaseInternalAnalysis)
  result.put("question_topic_comprehension", c.questionTopic)
  result.put("rewrite_report_comprehension", c.rewriteReport)

method toJson*(cfg: SkillConfig): JsonNode =
  result = newJObject()
  result.put("semantic_type", cfg.semanticType())
  result["recorte_bncc"] = cfg.skill.toJson()
  result["comprehensions"] = cfg.comprehensions.toJson()

method toJson*(p: StudentProfile): JsonNode =
  result = newJObject()
  result.put("semantic_type", p.semanticType())
  result.put("id", p.semanticId)
  result.put("nome", p.nome)
  result.put("etapa", p.etapa)
  result.put("serie", p.serie)
  result.put("faixa_etaria", p.faixaEtaria)
  result.put("fase", p.fase)
  result["funcionamento"] = arr(p.funcionamento)
  result["necessidades"] = arr(p.necessidades)
  result["evidencias_desejadas"] = arr(p.evidenciasDesejadas)

method toPrompt*(skill: BnccSkill): string =
  skill.toJson().pretty()

method toPrompt*(c: SkillComprehensions): string =
  c.toJson().pretty()

method toPrompt*(cfg: SkillConfig): string =
  cfg.toJson().pretty()

method toPrompt*(p: StudentProfile): string =
  p.toJson().pretty()

proc bnccContextBlock*(cfg: SkillConfig): string =
  cfg.toPrompt()

proc studentContextBlock*(profile: StudentProfile): string =
  profile.toPrompt()
