# Application main.
# Main = script corrido aplicado: domain local + signatures + modules + pipeline BNCC.
# Reusable stack only = stack/rlm + stack/dspy.
# Crown target = runAppFromJson*.
# HappyX/native shell target = runAppFromJson* or runShell* in src/native/happyx_native_shell.nim.

import std/[json, os, strformat, strutils]

import stack/[rlm, dspy]

# ============================================================
# 0. Domain models local to this application script
# ============================================================

type
  BnccSkill = object
    codigo: string
    etapa: string
    serieBase: string
    blocoBncc: string
    componente: string
    area: string
    campo: string
    praticaLinguagem: string
    objetoConhecimento: string
    habilidade: string
    fontePdfPagina: int

  SkillComprehensions = object
    bnccContext: string
    textBase: string
    textBaseInternalAnalysis: string
    questionTopic: string
    rewriteReport: string

  SkillConfig = object
    skill: BnccSkill
    comprehensions: SkillComprehensions

  StudentProfile = object
    id: string
    nome: string
    etapa: string
    serie: string
    faixaEtaria: string
    fase: string
    funcionamento: seq[string]
    necessidades: seq[string]
    evidenciasDesejadas: seq[string]

  GenerateTextBaseInput = object
    skillConfig: JsonNode
    studentProfile: JsonNode
    tema: string
    observacaoGeral: string

  GenerateQuestionsInput = object
    skillConfig: JsonNode
    studentProfile: JsonNode
    textBasePayload: JsonNode
    tema: string
    quantidade: int
    observacaoGeral: string

  GenerateRewriteReportInput = object
    skillConfig: JsonNode
    studentProfile: JsonNode
    textBasePayload: JsonNode
    quiz: JsonNode
    results: JsonNode

  AppStudyInput* = object
    tema*: string
    quantidade*: int
    observacaoGeral*: string
    fake*: bool

  AppStudyOutput* = object
    textBasePayload*: JsonNode
    quiz*: JsonNode
    rewriteReport*: string

# ============================================================
# 1. JSON helpers local to this application script
# ============================================================

proc arr(items: seq[string]): JsonNode =
  result = newJArray()
  for item in items:
    result.add(newJString(item))

proc put(node: JsonNode; key, value: string) =
  node[key] = newJString(value)

proc pickStr(node: JsonNode; keys: varargs[string]): string =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind != JNull:
      let value = node[key].getStr("")
      if value.len > 0:
        return value
  ""

proc pickObj(node: JsonNode; keys: varargs[string]): JsonNode =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind == JObject:
      return node[key]
  newJObject()

proc pickArr(node: JsonNode; keys: varargs[string]): JsonNode =
  for key in keys:
    if node.kind == JObject and node.hasKey(key) and node[key].kind == JArray:
      return node[key]
  newJArray()

proc toJson(s: BnccSkill): JsonNode =
  result = newJObject()
  result.put("codigo", s.codigo)
  result.put("etapa", s.etapa)
  result.put("serie_base", s.serieBase)
  result.put("bloco_bncc", s.blocoBncc)
  result.put("componente", s.componente)
  result.put("area", s.area)
  result.put("campo", s.campo)
  result.put("pratica_linguagem", s.praticaLinguagem)
  result.put("objeto_conhecimento", s.objetoConhecimento)
  result.put("habilidade", s.habilidade)
  result["fonte_pdf_pagina"] = newJInt(s.fontePdfPagina)

proc toJson(c: SkillComprehensions): JsonNode =
  result = newJObject()
  result.put("bncc_context_comprehension", c.bnccContext)
  result.put("text_base_comprehension", c.textBase)
  result.put("text_base_internal_analysis_comprehension", c.textBaseInternalAnalysis)
  result.put("question_topic_comprehension", c.questionTopic)
  result.put("rewrite_report_comprehension", c.rewriteReport)

proc toJson(cfg: SkillConfig): JsonNode =
  result = newJObject()
  result["recorte_bncc"] = toJson(cfg.skill)
  result["comprehensions"] = toJson(cfg.comprehensions)

proc toJson(p: StudentProfile): JsonNode =
  result = newJObject()
  result.put("id", p.id)
  result.put("nome", p.nome)
  result.put("etapa", p.etapa)
  result.put("serie", p.serie)
  result.put("faixa_etaria", p.faixaEtaria)
  result.put("fase", p.fase)
  result["funcionamento"] = arr(p.funcionamento)
  result["necessidades"] = arr(p.necessidades)
  result["evidencias_desejadas"] = arr(p.evidenciasDesejadas)

proc outputToJson*(outp: AppStudyOutput): JsonNode =
  result = newJObject()
  result["text_base_payload"] = outp.textBasePayload
  result["quiz"] = outp.quiz
  result.put("rewrite_report", outp.rewriteReport)

# ============================================================
# 2. Seed domain for the one BNCC study
# ============================================================

proc sampleSkillConfig(): JsonNode =
  let cfg = SkillConfig(
    skill: BnccSkill(
      codigo: "EF69LP01",
      etapa: "Ensino Fundamental",
      serieBase: "6º ao 9º ano do Ensino Fundamental",
      blocoBncc: "6º ao 9º ano do Ensino Fundamental",
      componente: "Língua Portuguesa",
      area: "Linguagens",
      campo: "Campo jornalístico-midiático",
      praticaLinguagem: "Leitura",
      objetoConhecimento: "Reconstrução do contexto de produção, circulação e recepção de textos",
      habilidade: "Diferenciar liberdade de expressão de discursos de ódio, posicionando-se contrariamente a esse tipo de discurso.",
      fontePdfPagina: 141
    ),
    comprehensions: SkillComprehensions(
      bnccContext: "A habilidade EF69LP01 exige interpretar manifestações públicas de linguagem, reconhecendo intenções, efeitos sociais e limites éticos dentro de espaços públicos e digitais.",
      textBase: "O texto-base deve tornar necessária a distinção entre crítica legítima e ataque discriminatório. Ele deve apresentar uma situação social plausível, com participantes, conflito, fala pública e consequência.",
      textBaseInternalAnalysis: "A análise interna deve mapear pistas textuais, participantes, interesses, erro provável do aluno e evidências de domínio. O texto precisa sustentar perguntas diagnósticas sem depender de opinião externa.",
      questionTopic: "As perguntas devem partir exclusivamente do texto-base, ser abertas e exigir justificativa com pistas explícitas. Elas devem observar reconhecimento de opinião legítima, discurso de ódio, limite da liberdade de expressão e resposta responsável.",
      rewriteReport: "O relatório deve avaliar se o texto-base, a compreensão-base, as perguntas e respostas produziram evidências suficientes, separando dificuldade do aluno, falha da pergunta e falha do texto-base."
    )
  )
  toJson(cfg)

proc sampleStudentProfile(): JsonNode =
  let profile = StudentProfile(
    id: "aluno_demo_efii_6",
    nome: "Aluno demonstracional EFII",
    etapa: "Ensino Fundamental II",
    serie: "6º ano do Ensino Fundamental",
    faixaEtaria: "11 a 12 anos",
    fase: "transição dos anos iniciais para os anos finais",
    funcionamento: @[
      "lê textos curtos e médios com autonomia parcial",
      "precisa aprender a justificar respostas com pistas do texto",
      "consegue reconhecer opinião explícita, mas pode confundir crítica com ofensa",
      "tende a responder por julgamento pessoal quando a pergunta exige evidência textual",
      "compreende melhor quando a situação usa gêneros próximos da vida social e digital"
    ],
    necessidades: @[
      "diferenciar crítica, discordância, xingamento, ameaça e discurso discriminatório",
      "reconhecer marcas linguísticas de generalização, inferiorização ou ataque a grupo",
      "identificar quando uma fala deixa de ser opinião e passa a ferir direitos",
      "posicionar-se contra discurso de ódio com justificativa textual",
      "indicar possibilidade de denúncia ou encaminhamento responsável"
    ],
    evidenciasDesejadas: @[
      "aponta expressão do texto que caracteriza ataque discriminatório",
      "explica a diferença entre discordar de uma ideia e atacar uma pessoa ou grupo",
      "reconhece que liberdade de expressão não autoriza humilhação, ameaça ou discriminação",
      "seleciona uma forma responsável de resposta ou denúncia",
      "justifica a resposta com base no texto-base"
    ]
  )
  toJson(profile)

# ============================================================
# 3. DSPy-like declarations imported from stack/dspy
# ============================================================

let GenerateTextBaseSig = signature(
  "GenerateTextBase",
  "GenerateTextBaseInput",
  "JsonNode(text_base_payload)",
  "Gera texto-base e compreensão-base para sondagem BNCC."
)

let GenerateQuestionsSig = signature(
  "GenerateQuestions",
  "GenerateQuestionsInput",
  "JsonNode(quiz)",
  "Gera perguntas abertas diagnósticas a partir de texto-base fixado."
)

let GenerateRewriteReportSig = signature(
  "GenerateRewriteReport",
  "GenerateRewriteReportInput",
  "string(report)",
  "Gera relatório textual de reescrita e diagnóstico."
)

let TextBaseModule = dspyModule("GenerateTextBaseModule", GenerateTextBaseSig)
let QuestionsModule = dspyModule("GenerateQuestionsModule", GenerateQuestionsSig)
let RewriteReportModule = dspyModule("GenerateRewriteReportModule", GenerateRewriteReportSig)

# ============================================================
# 4. Fake values for deterministic local study
# ============================================================

proc fakeTextBaseJson(): JsonNode =
  parseJson("""
{
  "bncc_codigo": "EF69LP01",
  "disciplina": "Língua Portuguesa",
  "etapa": "Ensino Fundamental",
  "serie": "6º ao 9º ano do Ensino Fundamental",
  "campo": "Campo jornalístico-midiático",
  "tema": "liberdade de expressão e discurso de ódio em comentários online",
  "abstracoes_narrativas": {
    "situacao_concreta": "fórum escolar sobre reforma do pátio e criação de hub digital",
    "participantes": ["Ana", "Bruno", "participante anônimo", "professora mediadora"],
    "tensao_central": "distinguir crítica legítima de ataque discriminatório",
    "pistas_textuais_planejadas": ["opiniões sobre uso do pátio", "ataque a grupo de estudantes", "mediação da professora"]
  },
  "texto_base": {
    "genero": "relato de fórum escolar",
    "titulo": "O comentário que passou do limite",
    "conteudo": "A Escola Municipal Jovens Leitores abriu um fórum online para ouvir estudantes, familiares e professores sobre a reforma do pátio e a criação de um hub digital. A proposta dividiu opiniões. Ana escreveu que gostava dos jogos no intervalo e perguntou se a escola não deveria reservar uma parte do espaço para brincadeiras. Bruno discordou, dizendo que o hub digital ajudaria nos estudos e nos projetos. Até esse ponto, os comentários apresentavam opiniões diferentes sobre a mesma proposta. O problema começou quando outro participante deixou de discutir a reforma e passou a atacar um grupo de estudantes, dizendo que eles não deveriam opinar porque eram inferiores e atrapalhavam a escola. A professora mediadora explicou que discordar de uma ideia é permitido, mas humilhar pessoas ou grupos ultrapassa o limite da liberdade de expressão."
  },
  "compreensao_base": {
    "situacao_comunicativa": "fórum online escolar",
    "finalidade_do_texto": "mostrar diferença entre opinião legítima e discurso discriminatório",
    "trecho_opiniao_legitima": "Ana questiona a perda do espaço de brincadeiras",
    "trecho_discurso_de_odio": "participante afirma que um grupo é inferior e não deveria opinar",
    "pistas_textuais": ["discordância sobre uso do pátio", "ataque a grupo de estudantes", "mediação da professora"],
    "erro_provavel_do_aluno": "confundir crítica à proposta com ataque às pessoas"
  }
}
""")

proc fakeQuestionsJson(textBasePayload: JsonNode; quantidade: int): JsonNode =
  let tb = pickObj(textBasePayload, "texto_base", "textoBase")
  result = parseJson("""
{
  "bncc_codigo": "EF69LP01",
  "disciplina": "Língua Portuguesa",
  "etapa": "Ensino Fundamental",
  "serie": "6º ao 9º ano do Ensino Fundamental",
  "campo": "Campo jornalístico-midiático",
  "tema": "liberdade de expressão e discurso de ódio em comentários online",
  "questions": [
    {
      "id": "q1",
      "tipo_resposta": "aberta",
      "habilidade_observada": "diferenciar crítica legítima de ataque discriminatório",
      "operacao_cognitiva": "comparar falas e justificar com evidência textual",
      "pergunta": "Qual comentário representa uma opinião legítima e qual comentário ultrapassa esse limite?",
      "enunciado_aberto": "Explique, com pistas do texto, a diferença entre a opinião sobre a reforma e o ataque feito a um grupo de estudantes.",
      "comando_para_o_aluno": "Responda usando pelo menos uma pista do texto-base.",
      "resposta_referencia": "A opinião legítima discute o uso do pátio ou do hub digital. O ataque ultrapassa o limite porque inferioriza um grupo de estudantes.",
      "rubrica_analise": {"dominio_observado":"usa pistas do texto", "dominio_em_formacao":"percebe exagero, mas justifica pouco", "resposta_sem_evidencia_textual":"opina sem citar o texto"},
      "pistas_textuais_esperadas": ["Ana questiona o uso do pátio", "outro participante chama um grupo de inferior", "a professora diferencia discordar de humilhar"],
      "intervencao_humana": "pedir ao aluno que localize no texto a fala que ataca pessoas",
      "erro_provavel": "achar que toda crítica é discurso de ódio",
      "evidencia_dominio": "explica que atacar grupo é diferente de discordar da proposta",
      "atualizacao_perfil": "observa sustentação textual na habilidade EF69LP01"
    },
    {
      "id": "q2",
      "tipo_resposta": "aberta",
      "habilidade_observada": "reconhecer limite da liberdade de expressão",
      "operacao_cognitiva": "interpretar consequência social da linguagem pública",
      "pergunta": "Por que a professora afirma que o comentário passou do limite?",
      "enunciado_aberto": "Explique por que, segundo o texto, a liberdade de expressão não autoriza humilhar pessoas ou grupos.",
      "comando_para_o_aluno": "Justifique sua resposta com uma informação do texto.",
      "resposta_referencia": "Porque o comentário deixou de discutir a proposta e passou a inferiorizar estudantes.",
      "rubrica_analise": {"dominio_observado":"relaciona liberdade de expressão ao limite contra discriminação", "dominio_em_formacao":"diz que foi errado, mas não explica o limite", "resposta_sem_evidencia_textual":"não cita o conflito do texto"},
      "pistas_textuais_esperadas": ["deixou de discutir a reforma", "passou a atacar um grupo", "humilhar ultrapassa o limite"],
      "intervencao_humana": "perguntar que parte do comentário atacou o grupo",
      "erro_provavel": "responder apenas que foi falta de educação",
      "evidencia_dominio": "identifica discriminação como limite da fala pública",
      "atualizacao_perfil": "reforça análise de manifestações públicas de linguagem"
    }
  ]
}
""")
  result["texto_base"] = tb
  let qs = pickArr(result, "questions")
  if quantidade > 0 and quantidade < qs.len:
    let trimmed = newJArray()
    for i in 0 ..< quantidade:
      trimmed.add(qs[i])
    result["questions"] = trimmed

proc fakeRewriteReport(): string =
  """RELATÓRIO DE REESCRITA

1. Diagnóstico do texto de contexto BNCC
O texto-base explicita uma situação pública de linguagem em ambiente digital escolar e permite observar a habilidade EF69LP01.

2. Qualidade do texto-base
Há conflito claro entre discordância sobre uma proposta e ataque discriminatório a um grupo.

3. Qualidade das perguntas
As perguntas exigem justificativa textual e permitem verificar se o estudante distingue crítica, ofensa e discurso de ódio.

4. Recomendação
A próxima versão pode ampliar a naturalidade das falas e explicitar mais consequências institucionais da mediação."""

# ============================================================
# 5. Prompts and module forward functions local to main
# ============================================================

proc buildTextBasePrompt(input: GenerateTextBaseInput): string =
  fmt"""
TEXT_BASE_TASK

Você é a inferência textual comum da aplicação Glauco.
Gere apenas o texto-base e sua compreensão-base dedicada para uma sondagem diagnóstica.
Não atue como agente RLM. Não gere perguntas nesta etapa.

TEMA:
{input.tema}

OBSERVAÇÃO HUMANA:
{input.observacaoGeral}

RECORTE BNCC:
{input.skillConfig["recorte_bncc"].pretty()}

PERFIL DO ALUNO:
{input.studentProfile.pretty()}

COMPREENSÕES:
{input.skillConfig["comprehensions"].pretty()}

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

proc buildQuestionsPrompt(input: GenerateQuestionsInput): string =
  fmt"""
QUESTIONS_TASK

Você é a inferência textual comum da aplicação Glauco.
Gere perguntas diagnósticas usando exclusivamente o texto-base recebido.
Não atue como agente RLM. Não gere novo texto-base.

TEMA:
{input.tema}

QUANTIDADE:
{input.quantidade}

RECORTE BNCC:
{input.skillConfig["recorte_bncc"].pretty()}

PERFIL DO ALUNO:
{input.studentProfile.pretty()}

TEXTO-BASE FIXADO:
{pickObj(input.textBasePayload, "texto_base", "textoBase").pretty()}

COMPREENSÃO-BASE:
{pickObj(input.textBasePayload, "compreensao_base", "compreensaoBase").pretty()}

RETORNE SOMENTE JSON VÁLIDO COM ESTA ESTRUTURA:
{{
  "bncc_codigo": "EF69LP01",
  "disciplina": "Língua Portuguesa",
  "etapa": "Ensino Fundamental",
  "serie": "6º ao 9º ano do Ensino Fundamental",
  "campo": "Campo jornalístico-midiático",
  "tema": "...",
  "texto_base": {{
    "genero": "...",
    "titulo": "...",
    "conteudo": "..."
  }},
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
- gerar exatamente {input.quantidade} perguntas;
- cada item de questions deve conter obrigatoriamente "id" e "enunciado_aberto" não vazios;
- usar somente perguntas abertas;
- cada pergunta deve exigir justificativa com pistas explícitas do texto-base;
- não gerar alternativas;
- não gerar novo texto-base.
"""

proc buildRewriteReportPrompt(input: GenerateRewriteReportInput): string =
  fmt"""
REWRITE_REPORT_TASK

Você é a inferência textual comum da aplicação Glauco.
Produza relatório textual para reescrever os textos do programa.
Não retornar JSON.

RECORTE BNCC:
{input.skillConfig["recorte_bncc"].pretty()}

COMPREENSÕES USADAS:
{input.skillConfig["comprehensions"].pretty()}

PERFIL DO ALUNO:
{input.studentProfile.pretty()}

TEXTO-BASE GERADO:
{input.textBasePayload.pretty()}

QUIZ GERADO:
{input.quiz.pretty()}

RESULTADOS OBSERVADOS:
{input.results.pretty()}

SEÇÕES:
1. Diagnóstico do texto de contexto BNCC
2. Diagnóstico da compreensão usada para gerar o texto-base
3. Qualidade do texto-base gerado
4. Qualidade das perguntas geradas
5. Evidências vindas das respostas do aluno
6. Separação entre dificuldade do aluno, falha da pergunta e falha do texto-base
7. Recomendações para reescrever as compreensões
"""

proc normalizeQuizFields(quiz: JsonNode; textBasePayload: JsonNode; quantidade: int): JsonNode =
  result = quiz

  if result.kind != JObject:
    result = newJObject()

  if not result.hasKey("texto_base"):
    result["texto_base"] = pickObj(textBasePayload, "texto_base", "textoBase")

  if not result.hasKey("questions") or result["questions"].kind != JArray:
    result["questions"] = newJArray()

  var idx = 0
  for item in result["questions"].items:
    inc idx
    if item.kind != JObject:
      continue

    let currentId = pickStr(item, "id", "codigo", "code", "numero")
    if currentId.len == 0:
      item["id"] = newJString("q" & $idx)

    let currentEnunciado = pickStr(item, "enunciado_aberto", "enunciadoAberto", "enunciado", "pergunta", "question", "questao", "questão")
    if currentEnunciado.len == 0:
      item["enunciado_aberto"] = newJString("Explique sua resposta com pistas do texto-base.")
    elif not item.hasKey("enunciado_aberto"):
      item["enunciado_aberto"] = newJString(currentEnunciado)

    if not item.hasKey("pergunta"):
      item["pergunta"] = newJString(pickStr(item, "enunciado_aberto", "enunciadoAberto", "enunciado", "question", "questao", "questão"))

  let qs = result["questions"]
  if quantidade > 0 and qs.len > quantidade:
    let trimmed = newJArray()
    for i in 0 ..< quantidade:
      trimmed.add(qs[i])
    result["questions"] = trimmed

proc forwardTextBase(ctx: DspyContext; input: GenerateTextBaseInput): JsonNode =
  let prompt = buildTextBasePrompt(input)
  let raw = predictJson(ctx, TextBaseModule, prompt, fakeTextBaseJson())

  if pickObj(raw, "texto_base", "textoBase").len == 0:
    raise newException(ValueError, "texto_base ausente no payload.")

  if pickObj(raw, "compreensao_base", "compreensaoBase").len == 0:
    raise newException(ValueError, "compreensao_base ausente no payload.")

  raw

proc forwardQuestions(ctx: DspyContext; input: GenerateQuestionsInput): JsonNode =
  let prompt = buildQuestionsPrompt(input)
  let raw = predictJson(ctx, QuestionsModule, prompt, fakeQuestionsJson(input.textBasePayload, input.quantidade))
  normalizeQuizFields(raw, input.textBasePayload, input.quantidade)

proc forwardRewriteReport(ctx: DspyContext; input: GenerateRewriteReportInput): string =
  let prompt = buildRewriteReportPrompt(input)
  predictText(ctx, RewriteReportModule, prompt, fakeRewriteReport())

# ============================================================
# 6. Study pipeline / execution
# ============================================================

proc simulatedResults(quiz: JsonNode): JsonNode =
  result = newJArray()
  let questions = pickArr(quiz, "questions")
  var idx = 0

  for q in questions.items:
    inc idx
    let item = newJObject()
    var qid = pickStr(q, "id", "codigo", "code", "numero")
    if qid.len == 0:
      qid = "q" & $idx

    item.put("id", qid)
    item.put("pergunta", pickStr(q, "enunciado_aberto", "enunciadoAberto", "pergunta", "question"))
    item.put("resposta_aluno", "O comentário passa do limite quando ataca um grupo, não apenas quando discorda da proposta.")
    item["evidencia_textual_suficiente"] = newJBool(true)
    item.put("observacao_humana", "resposta simulada para experimento de geração")
    result.add(item)

proc runStudy*(ctx: DspyContext; input: AppStudyInput): AppStudyOutput =
  let skillConfig = sampleSkillConfig()
  let studentProfile = sampleStudentProfile()

  ensureTrace(ctx, "bncc.study_generation", %*{
    "tema": input.tema,
    "quantidade": input.quantidade,
    "fake": ctx.fake
  })

  try:
    let textBasePayload = ctx.forwardTextBase(GenerateTextBaseInput(
      skillConfig: skillConfig,
      studentProfile: studentProfile,
      tema: input.tema,
      observacaoGeral: input.observacaoGeral
    ))

    let quiz = ctx.forwardQuestions(GenerateQuestionsInput(
      skillConfig: skillConfig,
      studentProfile: studentProfile,
      textBasePayload: textBasePayload,
      tema: input.tema,
      quantidade: input.quantidade,
      observacaoGeral: input.observacaoGeral
    ))

    let results = simulatedResults(quiz)

    let report = ctx.forwardRewriteReport(GenerateRewriteReportInput(
      skillConfig: skillConfig,
      studentProfile: studentProfile,
      textBasePayload: textBasePayload,
      quiz: quiz,
      results: results
    ))

    result = AppStudyOutput(
      textBasePayload: textBasePayload,
      quiz: quiz,
      rewriteReport: report
    )

    finishTrace(ctx, outputToJson(result))

  except CatchableError as e:
    failTrace(ctx, e.msg)
    raise

proc ensureDataDir() =
  createDir("data")

proc writeOutputs*(outp: AppStudyOutput) =
  ensureDataDir()
  writeFile("data/text_base.json", outp.textBasePayload.pretty())
  writeFile("data/quiz.json", outp.quiz.pretty())
  writeFile("data/rewrite_report.txt", outp.rewriteReport)

proc appInputFromJson*(params: JsonNode): AppStudyInput =
  AppStudyInput(
    tema: jstr(params, "tema", getEnv("BNCC_TEMA", "liberdade de expressão e discurso de ódio em comentários online")),
    quantidade: jint(params, "quantidade", parseInt(getEnv("BNCC_QUANTIDADE", "2"))),
    observacaoGeral: jstr(params, "observacao_geral", getEnv("BNCC_OBSERVACAO", "lê o texto, mas precisa justificar respostas com pistas explícitas")),
    fake: jbool(params, "fake", true)
  )

proc runApp*(input: AppStudyInput): JsonNode =
  let ctx = newDspyContext(defaultRLM(), fake = input.fake)
  let outp = runStudy(ctx, input)
  writeOutputs(outp)
  outputToJson(outp)

proc runAppFromJson*(params: JsonNode): JsonNode =
  runApp(appInputFromJson(params))

proc printSummary*(outJson: JsonNode; mode: string) =
  echo "=== Application main / BNCC generation ==="
  echo "Mode: " & mode
  echo ""

  let tb = pickObj(outJson["text_base_payload"], "texto_base", "textoBase")
  echo "Texto-base: " & pickStr(tb, "titulo", "title")

  let qs = pickArr(outJson["quiz"], "questions")
  echo "Perguntas: " & $qs.len

  var idx = 0
  for q in qs.items:
    inc idx
    var id = pickStr(q, "id", "codigo", "code", "numero")
    if id.len == 0:
      id = "q" & $idx
    let enunciado = pickStr(q, "enunciado_aberto", "enunciadoAberto", "enunciado", "pergunta", "question")
    echo "- " & id & ": " & enunciado

  echo ""
  echo "Arquivos gerados:"
  echo "- data/text_base.json"
  echo "- data/quiz.json"
  echo "- data/rewrite_report.txt"
  echo "- .rlm/traces.jsonl"
  echo "- .rlm/spans.jsonl"

proc mainCli*() =
  let args = commandLineParams()

  var useReal = false
  var wantsRepl = false
  var wantsShell = false

  for arg in args:
    case arg
    of "--real": useReal = true
    of "--repl": wantsRepl = true
    of "--shell": wantsShell = true
    else: discard

  if getEnv("USE_REAL_LM", "0") == "1":
    useReal = true

  if wantsRepl:
    let app = defaultRLM()
    repl(app)
    return

  if wantsShell:
    discard execShellCmd("nim c -r --path:src src/native/happyx_native_shell.nim")
    return

  let params = %*{
    "tema": getEnv("BNCC_TEMA", "liberdade de expressão e discurso de ódio em comentários online"),
    "quantidade": parseInt(getEnv("BNCC_QUANTIDADE", "2")),
    "observacao_geral": getEnv("BNCC_OBSERVACAO", "lê o texto, mas precisa justificar respostas com pistas explícitas"),
    "fake": not useReal
  }

  let outJson = runAppFromJson(params)
  printSummary(outJson, if useReal: "real LLM" else: "fake LLM")

when isMainModule:
  mainCli()
