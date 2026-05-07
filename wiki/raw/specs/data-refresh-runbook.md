---
source_url: https://github.com/giuice/GiuiceHunterPets/blob/main/docs/research/data-refresh-runbook.md
ingested: 2026-05-04
sha256: 8bc81347f4912afd2a547daef64a0d31a98359341d8f4ae9dea0645e7a956abb
---

# Data Refresh Runbook

## Visao Geral

`Data.lua` na raiz do repo eh o **baseline confiavel** (dataset shippado, validado por jogadores). O scrapper aplica atualizacoes do Wowhead em cima dele:

- Se Wowhead funciona pro pet -> scrapper vence.
- Se Wowhead falha pro pet -> usa o registro do `Data.lua` como fallback.
- Se uma familia inteira nao parseia ou nao tem cache -> carrega todos pets daquela familia direto do baseline.
- Build so falha se **zero** registros foram produzidos no total.

## Backends disponiveis

Existem dois CLIs equivalentes:

| Modulo | Velocidade | Quando usar |
|---|---|---|
| `scrapper.refresh_data_v_fast` | ~3-4x mais rapido | **Padrao recomendado.** Usa python urllib com gzip/brotli, keep-alive, headers Chrome completos, referer chain, jitter no delay. |
| `scrapper.refresh_data` | Mais lento, requer `agent-browser` | Fallback se algo der errado no v-fast. Mantido intocado pra estabilidade. |

Cache e manifest sao **compartilhados** entre os dois — pode alternar livremente.

## Passo a Passo (Pets)

### 1. Coleta (uma vez ou ate completar)

```bash
python3 -m scrapper.refresh_data_v_fast collect-pets --limit-pages 200 --delay 2
```

- Resumivel: rerode quantas vezes precisar, ele continua de onde parou.
- Erros HTTP individuais (403, 404, etc.) sao logados no manifest e o run **nao aborta mais**. Continue rodando ate o output reportar 0 paginas novas coletadas.
- Nao precisa mais de `while true; sleep 5; ...` por fora — `_collect_one` engole erros transientes e segue.
- Se Cloudflare comecar a 403'ar: suba `--delay 3` ou `--delay 4`. Espere alguns minutos antes de retomar.

### 2. Build a partir do cache

```bash
python3 -m scrapper.refresh_data_v_fast build-pets --from-cache --output scrapper/generated/Data.candidate.lua
```

- Le o `Data.lua` da raiz como baseline e passa para `generate_pets`.
- Output em `scrapper/generated/Data.candidate.lua` (NAO sobrescreva producao ainda).
- Build agora roda ate o fim mesmo com paginas ruins; usa baseline pra preencher buracos.

### 3. Inspecao dos relatorios

```bash
# Pets recuperados do baseline (scrape falhou, fallback fez efeito)
head -50 scrapper/generated/pet-fallback.md

# Pets sem fallback nem scrape (perdidos nessa rodada — geralmente dungeon pets)
head -50 scrapper/generated/pet-skipped.md

# Diferencas scraper vs baseline pra auditoria manual
head -50 scrapper/generated/pet-scraper-vs-baseline-diff.md
```

Procure no diff log:
- `ZONE_DIFF` -> Wowhead trocou o uiMapId; valide se a nova zona faz sentido.
- `COORD_COUNT_DIFF` -> contagem de coords mudou >50%; pode ser pet movido ou bug do parser.

### 4. Comparacao com producao

```bash
grep -c '\["NpcId"\]' Data.lua scrapper/generated/Data.candidate.lua
git diff --no-index Data.lua scrapper/generated/Data.candidate.lua | head -200
```

Esperado: candidate tem **menos** registros que `Data.lua` original — porque o parser do baseline descarta linhas com `zoneID=0` (cerca de 1400) que sempre falhariam na validacao. Isso eh por design.

### 5. Substituicao em producao

So substitua `Data.lua` quando:

- `pet-fallback.md` esta dentro do esperado (sem regressoes massivas).
- `pet-scraper-vs-baseline-diff.md` foi auditado linha a linha e os mismatches sao aceitaveis.
- `pet-validation-errors.md` esta vazio/ausente.
- Spot-check de pets de expansao atual existe no output.

```bash
cp Data.lua Data.lua.bak
cp scrapper/generated/Data.candidate.lua Data.lua
```

## Passo a Passo (Stable Masters)

### Coleta + Build

```bash
python3 -m scrapper.refresh_data_v_fast collect-stable-masters --limit-pages 200 --delay 2
python3 -m scrapper.refresh_data_v_fast build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
```

### Promocao

```bash
# Backup se ja existir, depois copia pra raiz
test -f StableMastersData.lua && cp StableMastersData.lua StableMastersData.lua.bak
cp scrapper/generated/StableMastersData.lua StableMastersData.lua
```

Stable masters **nao tem baseline shippado**; build skip-and-continue por registro mas sem fallback. Se zero stable masters validarem -> exit 1 com `stable-master-blockers.md`.

> **Nota:** a feature de pins de stable master in-game ainda nao esta implementada — gerar e copiar `StableMastersData.lua` so faz sentido depois que os arquivos Lua de renderizacao existirem (`MapStableMasterIndex.lua`, `GiuiceStableMasterPins.lua`). Veja `docs/plans/stable-master-pins.md`.

## Onde Fica o Estado

- `scrapper/generated/cache/` — paginas HTML cacheadas (compartilhado entre v-fast e classico).
- `scrapper/generated/refresh-manifest.json` — status por URL (ok / parse_error / error).
- Manifesto agora se auto-cura: pagina marcada como `parse_error` que parseia OK em build subsequente volta a `ok`.

## Limpeza de Cache Lixo

Runs antigas do `agent-browser` deixaram stubs de 39 bytes marcados como `ok`. Pra detectar e limpar:

```bash
python3 -c "
import json
from pathlib import Path
m_path = Path('scrapper/generated/refresh-manifest.json')
m = json.loads(m_path.read_text())
removed = []
for key, e in list(m['sources'].items()):
    p = Path(e['path']) if e.get('path') else None
    if p and p.exists() and p.stat().st_size < 1000:
        p.unlink()
        del m['sources'][key]
        removed.append(e['url'])
m_path.write_text(json.dumps(m, indent=2, sort_keys=True) + chr(10))
print(f'Removed {len(removed)} stub entries')
"
```

Depois rode `collect-pets` novamente — vai re-baixar essas paginas com headers corretos.

## Quando Usar `--reset-cache`

Quase nunca. So quando:
- Mudou estrutura de cache key.
- Quer forcar recoleta total (vai demorar horas mesmo com v-fast).

```bash
python3 -m scrapper.refresh_data_v_fast collect-pets --limit-pages 1 --delay 2 --reset-cache
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
- Aumente `--delay` no v-fast (default 2; tente 3 ou 4).

Pra inspecionar o manifest:

```bash
python3 -c "
import json
m = json.load(open('scrapper/generated/refresh-manifest.json'))
total = len(m['sources'])
ok = sum(1 for e in m['sources'].values() if e['status'] == 'ok')
print(f'Total: {total}  ok: {ok}  errored: {total - ok}')
"
```

## Source Shape (Referencia)

Validado em 2026-04-28/2026-05-02 com `agent-browser 0.26.0` e `FastFetcher` (urllib + gzip):

- `https://www.wowhead.com/hunter-pets` -> `g_listviews.pets.data` (familias).
- `https://www.wowhead.com/pet=<family-id>` -> `g_listviews.tameable.data` (pets da familia).
- `https://www.wowhead.com/npc=<npc-id>` -> `g_mapperData` (coordenadas).
- `https://www.wowhead.com/search?q=stable%20master` -> `g_listviews.npcs.data`. **Atencao:** desde 2026-05 a busca devolve `data: WH.getPageData("wowhead-guid…")` apontando para um `<script type="application/json" id="data.wowhead-guid…">[…]</script>` no mesmo HTML; `extract_listview_data` segue o ponteiro automaticamente.

Para NPCs sem locais mapeados, Wowhead serve `g_mapperData = []` ou omite a atribuicao — o parser trata os dois como "sem coords" (nao eh erro fatal).

## Decisoes Locked-in

| Topico | Decisao |
|---|---|
| Backend padrao | `refresh_data_v_fast` (FastFetcher python com gzip + keep-alive) |
| Fonte fallback | `Data.lua` shippado eh autoridade |
| `wow_pets.db` | Auxiliar/comparacao apenas |
| Drop em load | Linhas com `zoneID=0` ou sem coords sao descartadas |
| Conflito scraper vs baseline | Scraper vence quando scrape sucede; diff logado |
| Familia (id, nome) | Wowhead vence sobre baseline em fallback |
| `g_mapperData` vazio/ausente | Tratado como "sem coords" (nao fatal); cura manifest |
| Row malformada em listview de familia | Drop apenas a row; familia continua |
| Stable masters | Sem fallback, skip-and-continue por registro; pipeline pronto, integracao Lua pendente |
| Loop externo `while true` | Nao mais necessario |

## Comandos Equivalentes (referencia rapida)

| Acao | v-fast (recomendado) | classico |
|---|---|---|
| Coletar pets | `python3 -m scrapper.refresh_data_v_fast collect-pets --limit-pages 200 --delay 2` | `python3 -m scrapper.refresh_data collect-pets --limit-pages 200 --delay 5` |
| Build pets | `python3 -m scrapper.refresh_data_v_fast build-pets --from-cache --output scrapper/generated/Data.candidate.lua` | `python3 -m scrapper.refresh_data build-pets --from-cache --output scrapper/generated/Data.candidate.lua` |
| Coletar stable masters | `python3 -m scrapper.refresh_data_v_fast collect-stable-masters --limit-pages 200 --delay 2` | `python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 50 --delay 5` |
| Build stable masters | `python3 -m scrapper.refresh_data_v_fast build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua` | `python3 -m scrapper.refresh_data build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua` |
