## stack/utils/bncc_pipeline_types.nim
## Pipeline data classes used by the BNCC application main.
##
## Kept outside main.nim so the main remains a flowing applied pipeline,
## not a local type/object declaration file.

import std/[json, os, strutils]
import ./jsonx
import ./classx

Class GenerateTextBaseInput:
  skillConfig*: JsonNode
  studentProfile*: JsonNode
  tema*: string
  observacaoGeral*: string

Class GenerateQuestionsInput:
  skillConfig*: JsonNode
  studentProfile*: JsonNode
  textBasePayload*: JsonNode
  tema*: string
  quantidade*: int
  observacaoGeral*: string

Class GenerateResultsInput:
  skillConfig*: JsonNode
  studentProfile*: JsonNode
  textBasePayload*: JsonNode
  quiz*: JsonNode
  studentAnswers*: JsonNode
  observacaoGeral*: string

Class GenerateRewriteReportInput:
  skillConfig*: JsonNode
  studentProfile*: JsonNode
  textBasePayload*: JsonNode
  quiz*: JsonNode
  results*: JsonNode

Class AppStudyInput:
  tema*: string
  quantidade*: int
  observacaoGeral*: string
  studentAnswers*: JsonNode

Class AppStudyOutput:
  textBasePayload*: JsonNode
  quiz*: JsonNode
  results*: JsonNode
  rewriteReport*: string

proc newGenerateTextBaseInput*(
  skillConfig, studentProfile: JsonNode;
  tema, observacaoGeral: string
): GenerateTextBaseInput =
  GenerateTextBaseInput(
    semanticId: "GenerateTextBaseInput",
    semanticLabel: "Input de texto-base",
    semanticDescription: "Payload para geração do texto-base.",
    metadata: newJObject(),
    skillConfig: skillConfig,
    studentProfile: studentProfile,
    tema: tema,
    observacaoGeral: observacaoGeral
  )

proc newGenerateQuestionsInput*(
  skillConfig, studentProfile, textBasePayload: JsonNode;
  tema: string;
  quantidade: int;
  observacaoGeral: string
): GenerateQuestionsInput =
  GenerateQuestionsInput(
    semanticId: "GenerateQuestionsInput",
    semanticLabel: "Input de perguntas",
    semanticDescription: "Payload para geração de perguntas diagnósticas.",
    metadata: newJObject(),
    skillConfig: skillConfig,
    studentProfile: studentProfile,
    textBasePayload: textBasePayload,
    tema: tema,
    quantidade: quantidade,
    observacaoGeral: observacaoGeral
  )

proc newGenerateResultsInput*(
  skillConfig, studentProfile, textBasePayload, quiz, studentAnswers: JsonNode;
  observacaoGeral: string
): GenerateResultsInput =
  GenerateResultsInput(
    semanticId: "GenerateResultsInput",
    semanticLabel: "Input de análise de resultados",
    semanticDescription: "Payload para análise de respostas reais.",
    metadata: newJObject(),
    skillConfig: skillConfig,
    studentProfile: studentProfile,
    textBasePayload: textBasePayload,
    quiz: quiz,
    studentAnswers: studentAnswers,
    observacaoGeral: observacaoGeral
  )

proc newGenerateRewriteReportInput*(
  skillConfig, studentProfile, textBasePayload, quiz, results: JsonNode
): GenerateRewriteReportInput =
  GenerateRewriteReportInput(
    semanticId: "GenerateRewriteReportInput",
    semanticLabel: "Input de relatório de reescrita",
    semanticDescription: "Payload para relatório textual de reescrita.",
    metadata: newJObject(),
    skillConfig: skillConfig,
    studentProfile: studentProfile,
    textBasePayload: textBasePayload,
    quiz: quiz,
    results: results
  )

proc newAppStudyInput*(
  tema: string;
  quantidade: int;
  observacaoGeral: string;
  studentAnswers: JsonNode = newJArray()
): AppStudyInput =
  AppStudyInput(
    semanticId: "AppStudyInput",
    semanticLabel: tema,
    semanticDescription: "Input público do pipeline BNCC.",
    metadata: newJObject(),
    tema: tema,
    quantidade: quantidade,
    observacaoGeral: observacaoGeral,
    studentAnswers: studentAnswers
  )

proc newAppStudyOutput*(
  textBasePayload, quiz, results: JsonNode;
  rewriteReport: string
): AppStudyOutput =
  AppStudyOutput(
    semanticId: "AppStudyOutput",
    semanticLabel: "Resultado do pipeline",
    semanticDescription: "Saída pública do pipeline BNCC.",
    metadata: newJObject(),
    textBasePayload: textBasePayload,
    quiz: quiz,
    results: results,
    rewriteReport: rewriteReport
  )

method toJson*(outp: AppStudyOutput): JsonNode =
  result = newJObject()
  result["text_base_payload"] = outp.textBasePayload
  result["quiz"] = outp.quiz
  result["results"] = outp.results
  result.put("rewrite_report", outp.rewriteReport)

proc outputToJson*(outp: AppStudyOutput): JsonNode =
  outp.toJson()

proc answersFromJson*(params: JsonNode): JsonNode =
  if params.kind == JObject:
    let node = pickNode(params, "student_answers", "studentAnswers", "answers", "results")
    if node.kind != JNull:
      return node
  newJArray()

proc appStudyInputFromJson*(params: JsonNode): AppStudyInput =
  newAppStudyInput(
    tema = jstr(params, "tema", getEnv("BNCC_TEMA", "liberdade de expressão e discurso de ódio em comentários online")),
    quantidade = jint(params, "quantidade", parseInt(getEnv("BNCC_QUANTIDADE", "2"))),
    observacaoGeral = jstr(params, "observacao_geral", getEnv("BNCC_OBSERVACAO", "lê o texto, mas precisa justificar respostas com pistas explícitas")),
    studentAnswers = answersFromJson(params)
  )
