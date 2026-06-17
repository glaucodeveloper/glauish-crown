# Application main.
# Main = applied BNCC/DSPy pipeline target using real RLM execution.
# Memory/global semantic classes stay object-like through SmtModel.
# Execution parts are not modeled as classes: each program part runs inline in runAppFromJson*.
# Browser demo/Crown/native targets import runAppFromJson*.

import std/[json, os, strformat, strutils]

import stack/rlm except jstr, jint, jbool, pickStr, pickObj, pickArr, put
import stack/dspy
import stack/utils/[classx, jsonx]

# ============================================================
# 0. Semantic memory classes declared in this application script
# ============================================================

SmtModel BnccSkill:
  fields:
    codigo string
    etapa string
    serieBase string
    blocoBncc string
    componente string
    area string
    campo string
    praticaLinguagem string
    objetoConhecimento string
    habilidade string
    fontePdfPagina int

  methods:
    proc newBnccSkill*(
      codigo,
      etapa,
      serieBase,
      blocoBncc,
      componente,
      area,
      campo,
      praticaLinguagem,
      objetoConhecimento,
      habilidade: string;
      fontePdfPagina: int
    ): BnccSkill =
      BnccSkill(
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

    proc code*(self: BnccSkill): string =
      self.codigo

    proc shortLabel*(self: BnccSkill): string =
      self.codigo & " · " & self.componente & " · " & self.campo

    proc toPrompt*(self: BnccSkill): string =
      fmt"""{self.codigo} — {self.componente}/{self.area}
Etapa: {self.etapa}
Série-base: {self.serieBase}
Campo: {self.campo}
Prática de linguagem: {self.praticaLinguagem}
Objeto de conhecimento: {self.objetoConhecimento}
Habilidade: {self.habilidade}
Fonte PDF página: {self.fontePdfPagina}"""

    proc toJson*(self: BnccSkill): JsonNode =
      result = newJObject()
      result.put("codigo", self.codigo)
      result.put("etapa", self.etapa)
      result.put("serie_base", self.serieBase)
      result.put("bloco_bncc", self.blocoBncc)
      result.put("componente", self.componente)
      result.put("area", self.area)
      result.put("campo", self.campo)
      result.put("pratica_linguagem", self.praticaLinguagem)
      result.put("objeto_conhecimento", self.objetoConhecimento)
      result.put("habilidade", self.habilidade)
      result["fonte_pdf_pagina"] = newJInt(self.fontePdfPagina)

SmtModel SkillComprehensions:
  fields:
    bnccContext string
    textBase string
    textBaseInternalAnalysis string
    questionTopic string
    rewriteReport string

  methods:
    proc newSkillComprehensions*(
      bnccContext,
      textBase,
      textBaseInternalAnalysis,
      questionTopic,
      rewriteReport: string
    ): SkillComprehensions =
      SkillComprehensions(
        bnccContext: bnccContext,
        textBase: textBase,
        textBaseInternalAnalysis: textBaseInternalAnalysis,
        questionTopic: questionTopic,
        rewriteReport: rewriteReport
      )

    proc toPrompt*(self: SkillComprehensions): string =
      fmt"""BNCC context comprehension:
{self.bnccContext}

Text base comprehension:
{self.textBase}

Text base internal analysis comprehension:
{self.textBaseInternalAnalysis}

Question topic comprehension:
{self.questionTopic}

Rewrite report comprehension:
{self.rewriteReport}"""

    proc toJson*(self: SkillComprehensions): JsonNode =
      result = newJObject()
      result.put("bncc_context_comprehension", self.bnccContext)
      result.put("text_base_comprehension", self.textBase)
      result.put("text_base_internal_analysis_comprehension", self.textBaseInternalAnalysis)
      result.put("question_topic_comprehension", self.questionTopic)
      result.put("rewrite_report_comprehension", self.rewriteReport)

SmtModel SkillConfig:
  fields:
    skill BnccSkill
    comprehensions SkillComprehensions

  methods:
    proc newSkillConfig*(skill: BnccSkill; comprehensions: SkillComprehensions): SkillConfig =
      SkillConfig(skill: skill, comprehensions: comprehensions)

    proc code*(self: SkillConfig): string =
      self.skill.code()

    proc shortLabel*(self: SkillConfig): string =
      self.skill.shortLabel()

    proc toPrompt*(self: SkillConfig): string =
      self.skill.toPrompt() & "\n\n" & self.comprehensions.toPrompt()

    proc toJson*(self: SkillConfig): JsonNode =
      result = newJObject()
      result["recorte_bncc"] = self.skill.toJson()
      result["comprehensions"] = self.comprehensions.toJson()

SmtModel StudentProfile:
  fields:
    id string
    nome string
    etapa string
    serie string
    faixaEtaria string
    fase string
    funcionamento seq[string]
    necessidades seq[string]
    evidenciasDesejadas seq[string]

  methods:
    proc newStudentProfile*(
      id,
      nome,
      etapa,
      serie,
      faixaEtaria,
      fase: string;
      funcionamento,
      necessidades,
      evidenciasDesejadas: seq[string]
    ): StudentProfile =
      StudentProfile(
        id: id,
        nome: nome,
        etapa: etapa,
        serie: serie,
        faixaEtaria: faixaEtaria,
        fase: fase,
        funcionamento: funcionamento,
        necessidades: necessidades,
        evidenciasDesejadas: evidenciasDesejadas
      )

    proc shortLabel*(self: StudentProfile): string =
      self.nome & " · " & self.serie

    proc toPrompt*(self: StudentProfile): string =
      fmt"""Aluno: {self.nome}
Etapa: {self.etapa}
Série: {self.serie}
Faixa etária: {self.faixaEtaria}
Fase: {self.fase}
Funcionamento: {self.funcionamento.join("; ")}
Necessidades: {self.necessidades.join("; ")}
Evidências desejadas: {self.evidenciasDesejadas.join("; ")}"""

    proc toJson*(self: StudentProfile): JsonNode =
      result = newJObject()
      result.put("id", self.id)
      result.put("nome", self.nome)
      result.put("etapa", self.etapa)
      result.put("serie", self.serie)
      result.put("faixa_etaria", self.faixaEtaria)
      result.put("fase", self.fase)
      result["funcionamento"] = arr(self.funcionamento)
      result["necessidades"] = arr(self.necessidades)
      result["evidencias_desejadas"] = arr(self.evidenciasDesejadas)

# ============================================================
# 1. Global semantic memory data
# ============================================================

let ProgramBnccSkill* = newBnccSkill(
  codigo = "EF69LP01",
  etapa = "Ensino Fundamental",
  serieBase = "6º ao 9º ano do Ensino Fundamental",
  blocoBncc = "6º ao 9º ano do Ensino Fundamental",
  componente = "Língua Portuguesa",
  area = "Linguagens",
  campo = "Campo jornalístico-midiático",
  praticaLinguagem = "Leitura",
  objetoConhecimento = "Reconstrução do contexto de produção, circulação e recepção de textos",
  habilidade = "Diferenciar liberdade de expressão de discursos de ódio, posicionando-se contrariamente a esse tipo de discurso.",
  fontePdfPagina = 141
)

let ProgramComprehensions* = newSkillComprehensions(
  bnccContext = "A habilidade EF69LP01 exige interpretar manifestações públicas de linguagem, reconhecendo intenções, efeitos sociais e limites éticos dentro de espaços públicos e digitais.",
  textBase = "O texto-base deve tornar necessária a distinção entre crítica legítima e ataque discriminatório. Ele deve apresentar uma situação social plausível, com participantes, conflito, fala pública e consequência.",
  textBaseInternalAnalysis = "A análise interna deve mapear pistas textuais, participantes, interesses, erro provável do aluno e evidências de domínio. O texto precisa sustentar perguntas diagnósticas sem depender de opinião externa.",
  questionTopic = "As perguntas devem partir exclusivamente do texto-base, ser abertas e exigir justificativa com pistas explícitas. Elas devem observar reconhecimento de opinião legítima, discurso de ódio, limite da liberdade de expressão e resposta responsável.",
  rewriteReport = "O relatório deve avaliar se o texto-base, a compreensão-base, as perguntas e respostas produziram evidências suficientes, separando dificuldade do aluno, falha da pergunta e falha do texto-base."
)

let ProgramSkillConfig* = newSkillConfig(ProgramBnccSkill, ProgramComprehensions)

let ProgramStudentProfile* = newStudentProfile(
  id = "aluno_demo_efii_6",
  nome = "Aluno demonstracional EFII",
  etapa = "Ensino Fundamental II",
  serie = "6º ano do Ensino Fundamental",
  faixaEtaria = "11 a 12 anos",
  fase = "transição dos anos iniciais para os anos finais",
  funcionamento = @[
    "lê textos curtos e médios com autonomia parcial",
    "precisa aprender a justificar respostas com pistas do texto",
    "consegue reconhecer opinião explícita, mas pode confundir crítica com ofensa",
    "tende a responder por julgamento pessoal quando a pergunta exige evidência textual",
    "compreende melhor quando a situação usa gêneros próximos da vida social e digital"
  ],
  necessidades = @[
    "diferenciar crítica, discordância, xingamento, ameaça e discurso discriminatório",
    "reconhecer marcas linguísticas de generalização, inferiorização ou ataque a grupo",
    "identificar quando uma fala deixa de ser opinião e passa a ferir direitos",
    "posicionar-se contra discurso de ódio com justificativa textual",
    "indicar possibilidade de denúncia ou encaminhamento responsável"
  ],
  evidenciasDesejadas = @[
    "aponta expressão do texto que caracteriza ataque discriminatório",
    "explica a diferença entre discordar de uma ideia e atacar uma pessoa ou grupo",
    "reconhece que liberdade de expressão não autoriza humilhação, ameaça ou discriminação",
    "seleciona uma forma responsável de resposta ou denúncia",
    "justifica a resposta com base no texto-base"
  ]
)

# ============================================================
# 2. DSPy-like program declarations
# ============================================================

let GenerateTextBaseSig = signature(
  "GenerateTextBase",
  "JsonNode(program_state)",
  "JsonNode(text_base_payload)",
  "Gera texto-base e compreensão-base para sondagem BNCC."
)

let GenerateQuestionsSig = signature(
  "GenerateQuestions",
  "JsonNode(program_state + text_base_payload)",
  "JsonNode(quiz)",
  "Gera perguntas abertas diagnósticas a partir de texto-base fixado."
)

let GenerateResultsSig = signature(
  "GenerateResults",
  "JsonNode(program_state + quiz + student_answers)",
  "JsonNode(results)",
  "Analisa respostas reais do aluno contra o texto-base e o quiz."
)

let GenerateRewriteReportSig = signature(
  "GenerateRewriteReport",
  "JsonNode(program_state + generated_artifacts)",
  "string(report)",
  "Gera relatório textual de reescrita e diagnóstico."
)

let TextBaseModule = dspyModule("GenerateTextBaseModule", GenerateTextBaseSig)
let QuestionsModule = dspyModule("GenerateQuestionsModule", GenerateQuestionsSig)
let ResultsModule = dspyModule("GenerateResultsModule", GenerateResultsSig)
let RewriteReportModule = dspyModule("GenerateRewriteReportModule", GenerateRewriteReportSig)

# ============================================================
# 3. Public target: imperative execution narrative
# ============================================================

proc runAppFromJson*(params: JsonNode): JsonNode =
  # ------------------------------------------------------------
  # Read application parameters
  # ------------------------------------------------------------
  let tema = jstr(
    params,
    "tema",
    getEnv("BNCC_TEMA", "liberdade de expressão e discurso de ódio em comentários online")
  )

  let quantidade = jint(
    params,
    "quantidade",
    parseInt(getEnv("BNCC_QUANTIDADE", "2"))
  )

  let observacaoGeral = jstr(
    params,
    "observacao_geral",
    getEnv("BNCC_OBSERVACAO", "lê o texto, mas precisa justificar respostas com pistas explícitas")
  )

  var studentAnswers = newJArray()
  if params.kind == JObject:
    let picked = pickJson(params, "student_answers", "studentAnswers", "answers", "results")
    if picked.kind != JNull:
      studentAnswers = picked

  # ------------------------------------------------------------
  # Prepare global memory state for this execution
  # ------------------------------------------------------------
  let ctx = newDspyContext(defaultRLM())
  let skillConfig = ProgramSkillConfig.toJson()
  let studentProfile = ProgramStudentProfile.toJson()

  ensureTrace(ctx, "bncc.study_generation", %*{
    "tema": tema,
    "quantidade": quantidade,
    "student_answers_len": studentAnswers.len,
    "skill": ProgramSkillConfig.shortLabel(),
    "student": ProgramStudentProfile.shortLabel()
  })

  try:
    # ------------------------------------------------------------
    # GenerateTextBase
    # ------------------------------------------------------------
    var textBasePayload = newJObject()

    block GenerateTextBase:
      let prompt = fmt"""
TEXT_BASE_TASK

Você é a inferência textual comum da aplicação Glauco.
Gere apenas o texto-base e sua compreensão-base dedicada para uma sondagem diagnóstica.
Não atue como agente RLM. Não gere perguntas nesta etapa.

TEMA:
{tema}

OBSERVAÇÃO HUMANA:
{observacaoGeral}

RECORTE BNCC:
{skillConfig["recorte_bncc"].pretty()}

PERFIL DO ALUNO:
{studentProfile.pretty()}

COMPREENSÕES:
{skillConfig["comprehensions"].pretty()}

RETORNE SOMENTE JSON VÁLIDO COM ESTA ESTRUTURA:
{{
  "bncc_codigo": "EF69LP01",
  "disciplina": "Língua Portuguesa",
  "etapa": "Ensino Fundamental",
  "serie": "6º ao 9º ano do Ensino Fundamental",
  "campo": "Campo jornalístico-midiático",
  "tema": "...",
  "abstracoes_narrativas": {{
    "situacao_concreta": "...",
    "participantes": ["..."],
    "tensao_central": "...",
    "pistas_textuais_planejadas": ["..."]
  }},
  "texto_base": {{
    "genero": "...",
    "titulo": "...",
    "conteudo": "..."
  }},
  "compreensao_base": {{
    "situacao_comunicativa": "...",
    "finalidade_do_texto": "...",
    "trecho_opiniao_legitima": "...",
    "trecho_discurso_de_odio": "...",
    "pistas_textuais": ["..."],
    "erro_provavel_do_aluno": "..."
  }}
}}

REGRAS:
- não usar markdown;
- não usar bloco ```json;
- não gerar perguntas;
- texto_base.conteudo deve sustentar perguntas posteriores;
- preservar clareza entre crítica legítima e ataque discriminatório.
"""

      textBasePayload = predictJson(ctx, TextBaseModule, prompt)

      if pickObj(textBasePayload, "texto_base", "textoBase").len == 0:
        raise newException(ValueError, "texto_base ausente no payload.")

      if pickObj(textBasePayload, "compreensao_base", "compreensaoBase").len == 0:
        raise newException(ValueError, "compreensao_base ausente no payload.")

    # ------------------------------------------------------------
    # GenerateQuestions
    # ------------------------------------------------------------
    var quiz = newJObject()

    block GenerateQuestions:
      let prompt = fmt"""
QUESTIONS_TASK

Você é a inferência textual comum da aplicação Glauco.
Gere perguntas diagnósticas usando exclusivamente o texto-base recebido.
Não atue como agente RLM. Não gere novo texto-base.

TEMA:
{tema}

QUANTIDADE:
{quantidade}

RECORTE BNCC:
{skillConfig["recorte_bncc"].pretty()}

PERFIL DO ALUNO:
{studentProfile.pretty()}

TEXTO-BASE FIXADO:
{pickObj(textBasePayload, "texto_base", "textoBase").pretty()}

COMPREENSÃO-BASE:
{pickObj(textBasePayload, "compreensao_base", "compreensaoBase").pretty()}

RETORNE SOMENTE JSON VÁLIDO COM ESTA ESTRUTURA:
{{
  "bncc_codigo": "EF69LP01",
  "disciplina": "Língua Portuguesa",
  "etapa": "Ensino Fundamental",
  "serie": "6º ao 9º ano do Ensino Fundamental",
  "campo": "Campo jornalístico-midiático",
  "tema": "...",
  "texto_base": {{"genero": "...", "titulo": "...", "conteudo": "..."}},
  "questions": [
    {{
      "id": "q1",
      "tipo_resposta": "aberta",
      "habilidade_observada": "...",
      "operacao_cognitiva": "...",
      "pergunta": "...",
      "enunciado_aberto": "...",
      "comando_para_o_aluno": "...",
      "resposta_referencia": "...",
      "rubrica_analise": {{
        "dominio_observado": "...",
        "dominio_em_formacao": "...",
        "resposta_sem_evidencia_textual": "..."
      }},
      "pistas_textuais_esperadas": ["..."],
      "intervencao_humana": "...",
      "erro_provavel": "...",
      "evidencia_dominio": "...",
      "atualizacao_perfil": "..."
    }}
  ]
}}

REGRAS OBRIGATÓRIAS:
- gerar exatamente {quantidade} perguntas;
- cada item de questions deve conter obrigatoriamente "id" e "enunciado_aberto" não vazios;
- usar somente perguntas abertas;
- cada pergunta deve exigir justificativa com pistas explícitas do texto-base;
- não gerar alternativas;
- não gerar novo texto-base.
"""

      quiz = predictJson(ctx, QuestionsModule, prompt)

      if quiz.kind != JObject:
        quiz = newJObject()

      if not quiz.hasKey("texto_base"):
        quiz["texto_base"] = pickObj(textBasePayload, "texto_base", "textoBase")

      if not quiz.hasKey("questions") or quiz["questions"].kind != JArray:
        quiz["questions"] = newJArray()

      var idx = 0
      for item in quiz["questions"].items:
        inc idx
        if item.kind != JObject:
          continue

        let currentId = pickStr(item, "id", "codigo", "code", "numero")
        if currentId.len == 0:
          item["id"] = newJString("q" & $idx)

        let currentEnunciado = pickStr(
          item,
          "enunciado_aberto",
          "enunciadoAberto",
          "enunciado",
          "pergunta",
          "question",
          "questao",
          "questão"
        )

        if currentEnunciado.len == 0:
          item["enunciado_aberto"] = newJString("Explique sua resposta com pistas do texto-base.")
        elif not item.hasKey("enunciado_aberto"):
          item["enunciado_aberto"] = newJString(currentEnunciado)

        if not item.hasKey("pergunta"):
          item["pergunta"] = newJString(pickStr(
            item,
            "enunciado_aberto",
            "enunciadoAberto",
            "enunciado",
            "question",
            "questao",
            "questão"
          ))

      let qs = quiz["questions"]
      if quantidade > 0 and qs.len > quantidade:
        let trimmed = newJArray()
        for i in 0 ..< quantidade:
          trimmed.add(qs[i])
        quiz["questions"] = trimmed

    # ------------------------------------------------------------
    # GenerateResults
    # ------------------------------------------------------------
    var resultsJson = newJObject()

    block GenerateResults:
      if studentAnswers.kind == JNull:
        resultsJson.put("status", "sem_respostas_reais")
        resultsJson.put("reason", "studentAnswers veio como null.")
        resultsJson["items"] = newJArray()
      elif studentAnswers.kind == JObject and studentAnswers.len == 0:
        resultsJson.put("status", "sem_respostas_reais")
        resultsJson.put("reason", "Nenhuma resposta real foi informada.")
        resultsJson["items"] = newJArray()
      elif studentAnswers.kind == JArray and studentAnswers.len == 0:
        resultsJson.put("status", "sem_respostas_reais")
        resultsJson.put("reason", "Nenhuma resposta real foi informada.")
        resultsJson["items"] = newJArray()
      else:
        let prompt = fmt"""
RESULTS_ANALYSIS_TASK

Você é a inferência textual comum da aplicação Glauco.
Analise respostas reais do aluno para cada pergunta do quiz.
Não invente resposta de aluno.
Se não houver respostas reais, retorne status "sem_respostas_reais".

RECORTE BNCC:
{skillConfig["recorte_bncc"].pretty()}

PERFIL DO ALUNO:
{studentProfile.pretty()}

TEXTO-BASE:
{textBasePayload.pretty()}

QUIZ:
{quiz.pretty()}

RESPOSTAS REAIS DO ALUNO:
{studentAnswers.pretty()}

OBSERVAÇÃO HUMANA:
{observacaoGeral}

RETORNE SOMENTE JSON VÁLIDO COM ESTA ESTRUTURA:
{{
  "status": "analisado",
  "items": [
    {{
      "id": "q1",
      "pergunta": "...",
      "resposta_aluno": "...",
      "evidencia_textual_suficiente": true,
      "dominio_observado": "...",
      "dominio_em_formacao": "...",
      "dificuldade_do_aluno": "...",
      "falha_da_pergunta": "...",
      "falha_do_texto_base": "...",
      "intervencao_humana": "...",
      "atualizacao_perfil": "..."
    }}
  ],
  "sintese": {{
    "evidencias_suficientes": true,
    "principais_dificuldades": ["..."],
    "recomendacoes": ["..."]
  }}
}}

REGRAS:
- não simular respostas;
- não inventar evidência;
- se studentAnswers estiver vazio, usar status "sem_respostas_reais";
- analisar somente respostas presentes;
- justificar avaliação com base no texto-base e na rubrica do quiz;
- retornar somente JSON, sem markdown.
"""

        resultsJson = predictJson(ctx, ResultsModule, prompt)

    # ------------------------------------------------------------
    # GenerateRewriteReport
    # ------------------------------------------------------------
    var rewriteReport = ""

    block GenerateRewriteReport:
      let prompt = fmt"""
REWRITE_REPORT_TASK

Você é a inferência textual comum da aplicação Glauco.
Produza relatório textual para reescrever os textos do programa.
Não retornar JSON.

RECORTE BNCC:
{skillConfig["recorte_bncc"].pretty()}

COMPREENSÕES USADAS:
{skillConfig["comprehensions"].pretty()}

PERFIL DO ALUNO:
{studentProfile.pretty()}

TEXTO-BASE GERADO:
{textBasePayload.pretty()}

QUIZ GERADO:
{quiz.pretty()}

RESULTADOS OBSERVADOS:
{resultsJson.pretty()}

SEÇÕES:
1. Diagnóstico do texto de contexto BNCC
2. Diagnóstico da compreensão usada para gerar o texto-base
3. Qualidade do texto-base gerado
4. Qualidade das perguntas geradas
5. Evidências vindas das respostas do aluno
6. Separação entre dificuldade do aluno, falha da pergunta e falha do texto-base
7. Recomendações para reescrever as compreensões
"""

      rewriteReport = predictText(ctx, RewriteReportModule, prompt)

    # ------------------------------------------------------------
    # Persist and return public output
    # ------------------------------------------------------------
    let outputJson = newJObject()
    outputJson["text_base_payload"] = textBasePayload
    outputJson["quiz"] = quiz
    outputJson["results"] = resultsJson
    outputJson.put("rewrite_report", rewriteReport)

    createDir("data")
    writeFile("data/text_base.json", textBasePayload.pretty())
    writeFile("data/quiz.json", quiz.pretty())
    writeFile("data/results.json", resultsJson.pretty())
    writeFile("data/rewrite_report.txt", rewriteReport)

    finishTrace(ctx, outputJson)
    return outputJson

  except CatchableError as e:
    failTrace(ctx, e.msg)
    raise

# ============================================================
# 4. CLI target
# ============================================================

proc mainCli*() =
  let args = commandLineParams()

  var wantsRepl = false
  var wantsShell = false
  var wantsBrowserDemo = false

  for arg in args:
    case arg
    of "--repl": wantsRepl = true
    of "--shell": wantsShell = true
    of "--browser-demo": wantsBrowserDemo = true
    else: discard

  if wantsRepl:
    let app = defaultRLM()
    repl(app)
    return

  if wantsShell:
    discard execShellCmd("nim c -r --path:src src/native/happyx_native_shell.nim")
    return

  if wantsBrowserDemo:
    discard execShellCmd("nim c -r --path:src src/native/app_browser_demo.nim")
    return

  let params = %*{
    "tema": getEnv("BNCC_TEMA", "liberdade de expressão e discurso de ódio em comentários online"),
    "quantidade": parseInt(getEnv("BNCC_QUANTIDADE", "2")),
    "observacao_geral": getEnv("BNCC_OBSERVACAO", "lê o texto, mas precisa justificar respostas com pistas explícitas"),
    "student_answers": jsonFromEnvOrDefault("BNCC_STUDENT_ANSWERS", newJArray())
  }

  let outJson = runAppFromJson(params)

  echo "=== Application main / BNCC generation ==="
  echo "Mode: real RLM"
  echo ""

  let tb = pickObj(outJson["text_base_payload"], "texto_base", "textoBase")
  echo "Texto-base: " & pickStr(tb, "titulo", "title")

  let qs = pickArr(outJson["quiz"], "questions")
  echo "Perguntas: " & $qs.len

  var idx = 0
  for q in qs.items:
    inc idx
    var qid = pickStr(q, "id", "codigo", "code", "numero")
    if qid.len == 0:
      qid = "q" & $idx
    let enunciado = pickStr(q, "enunciado_aberto", "enunciadoAberto", "enunciado", "pergunta", "question")
    echo "- " & qid & ": " & enunciado

  echo ""
  echo "Results status: " & pickStr(outJson["results"], "status")
  echo ""
  echo "Arquivos gerados:"
  echo "- data/text_base.json"
  echo "- data/quiz.json"
  echo "- data/results.json"
  echo "- data/rewrite_report.txt"
  echo "- .rlm/traces.jsonl"
  echo "- .rlm/spans.jsonl"

when isMainModule:
  mainCli()
