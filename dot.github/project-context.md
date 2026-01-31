# Project Context - BMF (Brainrot Mining Factory)

This file contains project-specific information that complements the general architecture rules in `copilot-instructions.md`.

---

## Game Description

**BMF** é um **Tycoon de Mineração** onde jogadores constroem fábricas de processamento de minérios para ganhar dinheiro.

### Conceito Principal
- Jogador possui um **Plot** (terreno) onde pode colocar máquinas
- **Ore Spawners** geram minérios (ores) periodicamente
- **Conveyors** (esteiras) transportam os minérios
- **Upgraders** aumentam o valor dos minérios que passam por eles
- **Sellers** vendem os minérios por Cash
- **Brainrots** são pets/personagens colecionáveis que ajudam na mineração
- Sistema de **Rebirth** para progressão a longo prazo

### Loop Principal de Gameplay
```
Ore Spawner → Conveyor → Upgrader(s) → Conveyor → Seller → Cash
```

---

## Development Stage

Early Development

---

## Robustness Level

Level 1 (Basic)

---

## Project-Specific Decisions

- Usar OOP com Classes simples (não ECS)
- Cada máquina colocada será uma instância de classe
- Ores serão objetos físicos com physics

---

## Game Systems Overview

### 1. Placement System
O jogador pode colocar itens no seu plot através de uma UI de loja.

**Como funciona:**
Em Grids de 6x6x6, tem q ter o Y de altura pois também é possível criar mais andares

**Validações necessárias:**
- Player tem dinheiro suficiente?
- Posição está disponível no plot?
- Player tem o item no inventário?

---

### 2. Ore Processing System
Minérios são gerados e processados nas esteiras.

**Spawners (Ore):**
- Cada Ore Spawner gera minérios periodicamente
- Diferentes tipos de ores têm valores diferentes
<!-- PREENCHER: Intervalo de spawn? Limite de ores simultâneos? -->

**Conveyors (Esteiras):**
- Transportam ores na direção configurada
- Diferentes velocidades por tier
<!-- PREENCHER: Como detecta colisão? TouchEnded? Raycast? -->

**Upgraders:**
- Aumentam o valor do ore que passa
- Limite de upgrades por ore (máximo 3?)
<!-- PREENCHER: Upgrader afeta ore uma vez só ou pode re-upgradar? -->

**Sellers:**
- Convertem ores em Cash
- Diferentes multiplicadores por tier
- Podem ter limite de dinheiro acumulado (MoneyLimit)
<!-- PREENCHER: Seller precisa ser coletado manualmente ou auto-deposita? -->

---

### 3. Brainrot System (Pets)
Brainrots são personagens colecionáveis que ajudam o jogador.

**Obtenção:**
- Através de Crates (caixas)

**Funcionalidade:**
<!-- PREENCHER: O que os Brainrots fazem exatamente? -->
- Dados existentes indicam: `DropsPerSecond`, `DropCooldown`, `MiningSpeed`
- Parecem ajudar a gerar mais ores ou mais rápido

**Equipamento:**
<!-- PREENCHER: Quantos podem ser equipados? Onde ficam visualmente? -->

---

### 4. Crate System
Caixas que dão Brainrots aleatórios.

**Tipos de Crates (existentes nos dados):**
| Crate | Preço | Raridade Mínima |
|-------|-------|-----------------|
| Normal Crate | 500 | Common |
| Golden Crate | 12,500 | Uncommon |
| Mystic Crate | 50,000 | Rare |

**Mecânica:**
- Cada crate tem odds diferentes para cada Brainrot
- Sistema de "Level" com LevelChances e LevelLuck
<!-- PREENCHER: O que são os Levels? Afeta qual brainrot cai? -->

---

### 5. Rebirth System
Sistema de prestígio/reset para progressão a longo prazo.

**Requisitos para Rebirth (dados existentes):**
- Ter determinado Cash
- Ter determinados Brainrots

**Rewards de Rebirth:**
- Desbloqueia novos Placables (máquinas)
- Aumenta OreLimit
- Aumenta outros limites?

**O que reseta no Rebirth:**
dinheiro

---

### 6. Shop/Stock System
Sistema de loja com estoque rotativo.

**Mecânica (baseado nos dados):**
- Cada item tem `StockData`: `Min`, `Max`, `Odds`
- Parece ser um sistema de estoque aleatório que refresha periodicamente
- O Refresh ocorre a cada x minutos

---

### 7. Economy System
Sistema de dinheiro e transações.

**Moedas:**
- **Cash** — Moeda principal, ganha vendendo ores
- **Rebirths** — Conta de rebirths feitos

**Ganho de Cash:**
- Vendendo ores nos Sellers

**Gastos de Cash:**
- Comprando itens na loja
- Abrindo crates
- Upgrades?

---

## Data Reference (do projeto anterior)

Os seguintes arquivos de dados existem e podem servir de referência:

| Arquivo | Conteúdo |
|---------|----------|
| `ReplicatedStorage/Data/Placables` | Todos os itens colocáveis (Conveyors, Sellers, Upgraders, Ores) |
| `ReplicatedStorage/Data/Brainrots` | Todos os Brainrots com stats |
| `ReplicatedStorage/Data/Crate` | Configuração das crates e odds |
| `ReplicatedStorage/Data/Rebirth` | Requisitos e rewards de cada rebirth |
| `ReplicatedStorage/Data/Settings` | Configurações do player (volumes) |
| `ReplicatedStorage/Shared/DataTemplate` | Template de dados do player |

### Estrutura do PlayerData (existente):
```lua
{
    Cash = 0,
    Rebirths = 0,
    AveragePerSecond = 0,
    LogOutTime = math.huge,
    
    InventorySize = 100,
    OreLimit = 50,
    UpgradeLimit = 3,
    
    Hotbar = {},
    Inventory = {
        Placable = {},
        Brainrot = {},
    },
    
    Index = {},
    PurchaseHistory = {},
    Gamepasses = {},
    Boosts = {},
    Settings = {...},
    RedeemedCodes = {},
    
    TutorialData = {
        Finished = false,
        Stage = 0,
        CrateOpened = false
    },
    
    PlacablesStock = {
        LastTimestamp = 0,
        Stock = {},
    },
    
    Plot = {},  -- Dados do plot salvo
}
```

---

## Assets Existentes

### Models (ReplicatedStorage/Assets)
- `Brainrots/` — Models de todos os Brainrots
- `Building/Conveyors/` — Models das esteiras
- `Building/Sellers/` — Models dos sellers
- `Building/Upgraders/` — Models dos upgraders
- `Building/Ores/` — Models dos ore spawners
- `Ores/` — Models dos minérios físicos
- `Crates/` — Models das caixas
- `VFX/` — Efeitos visuais

### UI (StarterGui)
- `Frames/` — UIs principais (Backpack, BlocksShop, CrateShop, etc.)
- `Menus/` — Menus (Boosts, Hotbar, etc.)
- `PopUps/` — Popups (Notifications, Tutorial, etc.)

### Map (Workspace)
- `Map/` — Mapa base com Lobby, Plates (plots), etc.
- `Assets/` — Máquinas de exemplo no mundo

---

## Questions to Answer

<!-- Estas perguntas precisam ser respondidas para implementar os sistemas -->

### Placement
1. Como funciona o posicionamento? Grid-based ou free placement?
2. Player compra direto da loja ou primeiro vai pro inventário?
3. Pode rotacionar os itens? Em quantos graus?
4. Como funciona a remoção de itens? Volta pro inventário?

### Ore Processing
1. Qual o limite de ores simultâneos no plot?
2. Como os ores se movem nas esteiras? Physics com BodyVelocity?
3. Upgrader pode afetar o mesmo ore múltiplas vezes?
4. Seller deposita automático ou player precisa coletar?

### Brainrots
1. Quantos Brainrots podem ser equipados ao mesmo tempo?
2. O que fazem exatamente? Spawnam ores extra? Aumentam velocidade?
3. Onde ficam visualmente? Seguem o player? Ficam no plot?

### Progression
1. O que reseta no Rebirth?
2. Como funciona o Stock refresh? Timer? Daily?
3. Existe sistema de Offline Earnings?

---

## TODO (Technical)

<!-- Tarefas técnicas a serem implementadas -->

- [ ] Criar estrutura base do projeto (folders, Main scripts)
- [ ] Implementar RemotesManager + RemotesData
- [ ] Implementar ProfileManager com ProfileStore
- [ ] Implementar sistema de Plot (save/load)
- [ ] Implementar Placement System
- [ ] Implementar Ore Processing (spawners, conveyors, upgraders, sellers)
- [ ] Implementar Crate System
- [ ] Implementar Brainrot System
- [ ] Implementar Rebirth System
- [ ] Implementar Shop/Stock System
- [ ] Implementar UI Controllers

---

## Current Focus

Definindo sistemas e arquitetura do jogo.

---

## Known Limitations / Technical Debt

- None yet

---

## Personal Notes

<!-- Espaço para anotações do desenvolvedor -->

