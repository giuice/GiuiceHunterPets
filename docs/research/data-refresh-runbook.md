# Data Refresh Runbook

## Visao Geral

`Data.lua` na raiz do repo eh o **baseline confiavel** (dataset shippado, validado por jogadores). O scrapper aplica atualizacoes do Wowhead em cima dele:

- Se Wowhead funciona pro pet -> scrapper vence.
- Se Wowhead falha pro pet -> usa o registro do `Data.lua` como fallback.
- Se uma familia inteira nao parseia ou nao tem cache -> carrega todos pets daquela familia direto do baseline.
- Build so falha se **zero** registros foram produzidos no total.

## Passo a Passo (Pets)

### 1. Coleta (uma vez ou ate completar)

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 200 --delay 5
```

- Resumivel: rerode quantas vezes precisar, ele continua de onde parou.
- Erros HTTP individuais (403, 404, etc.) sao logados no manifest e o run **nao aborta mais**. Continue rodando ate o output reportar 0 paginas novas coletadas.
- Nao precisa mais de `while true; sleep 5; ...` por fora — `_collect_one` engole erros transientes e segue.

### 2. Build a partir do cache

```bash
rtk python3 -m scrapper.refresh_data build-pets --from-cache --output /tmp/Data.test.lua
```

- Le o `Data.lua` da raiz como baseline e passa para `generate_pets`.
- Output em `/tmp/Data.test.lua` (NAO sobrescreva producao ainda).
- Build agora roda ate o fim mesmo com paginas ruins; usa baseline pra preencher buracos.

### 3. Inspecao dos relatorios

```bash
# Pets recuperados do baseline (scrape falhou, fallback fez efeito)
head -50 scrapper/generated/pet-fallback.md

# Pets sem fallback nem scrape (perdidos nessa rodada)
head -50 scrapper/generated/pet-skipped.md

# Diferencas scraper vs baseline pra auditoria manual
head -50 scrapper/generated/pet-scraper-vs-baseline-diff.md
```

Procure no diff log:
- `ZONE_DIFF` -> Wowhead trocou o uiMapId; valide se a nova zona faz sentido.
- `COORD_COUNT_DIFF` -> contagem de coords mudou >50%; pode ser pet movido ou bug do parser.

### 4. Comparacao com producao

```bash
grep -c '\["NpcId"\]' Data.lua /tmp/Data.test.lua
git diff --no-index Data.lua /tmp/Data.test.lua | head -200
```

Esperado: `/tmp/Data.test.lua` tem **menos** registros que `Data.lua` original — porque o parser do baseline descarta linhas com `zoneID=0` (cerca de 1400) que sempre falhariam na validacao. Isso eh por design.

### 5. Substituicao em producao

So substitua `Data.lua` quando:

- `pet-fallback.md` esta dentro do esperado (sem regressoes massivas).
- `pet-scraper-vs-baseline-diff.md` foi auditado linha a linha e os mismatches sao aceitaveis.
- `pet-validation-errors.md` esta vazio/ausente.
- Spot-check de pets de expansao atual existe no output.

```bash
cp /tmp/Data.test.lua Data.lua
```

## Passo a Passo (Stable Masters)

```bash
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 50 --delay 5
rtk python3 -m scrapper.refresh_data build-stable-masters --from-cache --output /tmp/StableMastersData.test.lua
head -50 scrapper/generated/stable-master-skipped.md
```

Stable masters **nao tem baseline shippado**; build agora skip-and-continue por registro mas nao tem fallback. Se zero stable masters validarem -> exit 1 com `stable-master-blockers.md`.

## Onde Fica o Estado

- `scrapper/generated/cache/` — paginas HTML cacheadas.
- `scrapper/generated/refresh-manifest.json` — status por URL (ok / parse_error / error).
- Manifesto agora se auto-cura: pagina marcada como `parse_error` que parseia OK em build subsequente volta a `ok`.

## Quando Usar `--reset-cache`

Quase nunca. So quando:
- Mudou estrutura de cache key.
- Quer forcar recoleta total (vai demorar horas com `--delay 5`).

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 1 --delay 5 --reset-cache
```

## Diagnostico de Falhas

Se `build-pets` exit 1 (zero registros — caso extremo):

```bash
sed -n '1,120p' scrapper/generated/pet-refresh-blockers.md
```

Causas plausiveis:
- Cache totalmente vazio E `Data.lua` ausente.
- `Data.lua` corrompido a ponto do parser nao achar `GHP.pet_by_zones = {`.

Se Wowhead esta retornando 403 em massa:
- Continue rodando `collect-pets` periodicamente; o build ja nao depende mais de coleta perfeita.
- O baseline cobre o gap.

## Source Shape (Referencia)

Validado em 2026-04-28/2026-04-29 com `agent-browser 0.26.0`:

- `https://www.wowhead.com/hunter-pets` -> `g_listviews.pets.data` (familias).
- `https://www.wowhead.com/pet=<family-id>` -> `g_listviews.tameable.data` (pets da familia).
- `https://www.wowhead.com/npc=<npc-id>` -> `g_mapperData` (coordenadas).
- `https://www.wowhead.com/search?q=stable%20master` -> `g_listviews.npcs.data`.

## Decisoes Locked-in

| Topico | Decisao |
|---|---|
| Fonte fallback | `Data.lua` shippado eh autoridade |
| `wow_pets.db` | Auxiliar/comparacao apenas |
| Drop em load | Linhas com `zoneID=0` ou sem coords sao descartadas |
| Conflito scraper vs baseline | Scraper vence quando scrape sucede; diff logado |
| Familia (id, nome) | Wowhead vence sobre baseline em fallback |
| Stable masters | Sem fallback, skip-and-continue por registro |
| Loop externo `while true` | Nao mais necessario |
