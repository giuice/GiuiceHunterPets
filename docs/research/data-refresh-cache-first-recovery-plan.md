# Data Refresh Cache-First Recovery Plan

## Contexto

O refresh atual falhou operacionalmente porque tratou coleta de dados como uma execucao comum de pipeline. Isso foi errado para scraping: Wowhead pode bloquear acesso, mudar shape de dados, demorar a responder ou carregar dados apenas depois de JavaScript/browser. A prioridade agora e proteger o cache, reduzir acessos e separar coleta de geracao.

## Regras Imediatas

- Nao rodar refresh completo contra Wowhead sem plano de coleta.
- Nao gerar `Data.sample.lua` automaticamente.
- Nao apagar HTML cacheado por erro de parser, validacao ou shape.
- Nao usar concorrencia contra Wowhead.
- Nao repetir acesso para diagnosticar parser quando ja houver HTML em `scrapper/generated/cache/`.
- Nao substituir `Data.lua` nem criar `StableMastersData.lua` sem revisao manual do gerado.

## Objetivo

Transformar o processo em duas etapas separadas:

1. Coleta cache-first: baixar ou capturar paginas fonte e salvar em `scrapper/generated/cache/`.
2. Geracao offline: ler somente o cache existente, validar, e entao gerar Lua.

## Comportamento Desejado

### Cache

- Cada URL deve ter um arquivo cacheado em `scrapper/generated/cache/<sha>.html`.
- O manifesto `scrapper/generated/refresh-manifest.json` deve manter `path` mesmo quando houver erro semantico.
- Erros de rede podem registrar `status: error` sem `path`.
- Erros de parser/validacao devem registrar algo como `status: parse_error` ou `status: validation_error`, mas mantendo `path`.
- `--reset-cache` deve ser raro e explicito.

### Coleta

- Coleta deve ser serial.
- Deve existir delay configuravel entre paginas.
- Deve haver limite explicito de paginas por execucao.
- Deve ser possivel continuar do ultimo ponto usando o manifesto.
- Browser/agent-browser pode ser usado como fonte de captura, mas sempre salvando no cache antes de parsear.

### Geracao

- Geracao de Lua deve poder rodar offline.
- Se faltar pagina no cache, deve falhar dizendo qual URL falta.
- Se o parser falhar, deve apontar o arquivo cacheado local para inspecao.
- Nenhum arquivo final deve ser escrito se a validacao nao passar.

## Comandos Que Deveriam Existir

Exemplo de desenho operacional, ainda nao implementado:

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 10 --delay 5 --browser
rtk python3 -m scrapper.refresh_data build-pets --output scrapper/generated/Data.lua --from-cache
```

Para stable masters:

```bash
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 10 --delay 5 --browser
rtk python3 -m scrapper.refresh_data build-stable-masters --output scrapper/generated/StableMastersData.lua --from-cache
```

## Situacao Atual

- Existe cache de `https://www.wowhead.com/hunter-pets` em `scrapper/generated/cache/`.
- O erro atual registrado em `scrapper/generated/pet-refresh-blockers.md` indica bloqueio ou falha de acesso anterior.
- O proximo trabalho deve comecar lendo o cache local, nao fazendo nova chamada de rede.

## Proxima Mudanca Recomendada

Primeiro ajuste pequeno e seguro:

- mudar `SourceCache.invalidate()` ou os chamadores para nao apagar arquivo cacheado quando o erro for semantico;
- manter `path` no manifesto para erro de parser/validacao;
- atualizar mensagens para apontar para o arquivo cacheado local.

Depois disso:

- separar `collect-*` de `build-*`;
- adicionar delay/limite;
- documentar o fluxo final no runbook.

