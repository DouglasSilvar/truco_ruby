
# Truco API - Projeto Ruby on Rails

Bem-vindo ao projeto Truco API, uma API desenvolvida em Ruby on Rails para gerenciar salas e jogadores de um jogo de truco.

## Índice
- [Requisitos](#requisitos)
- [Instalação e Build](#instalação-e-build)
- [Como Executar](#como-executar)
- [Rotas da API](#rotas-da-api)
  - [Jogadores](#jogadores)
    - [Listar Jogadores](#1-listar-jogadores)
    - [Criar Jogador](#2-criar-jogador)
    - [Validar Jogador](#3-validar-jogador)
  - [Salas](#salas)
    - [Listar Salas](#1-listar-salas)
    - [Criar Sala](#2-criar-sala)
    - [Entrar em uma Sala](#3-entrar-em-uma-sala)
    - [Sair de uma Sala](#4-sair-de-uma-sala)
    - [Alterar Cadeira](#5-alterar-cadeira)
    - [Expulsar Jogador](#6-expulsar-jogador)
    - [Alterar Status de Pronto](#7-alterar-status-de-pronto)
    - [Iniciar Partida](#8-iniciar-partida)
  - [Jogos](#jogos)
    - [Exibir Jogo](#1-exibir-jogo)
    - [Fazer Jogada](#2-fazer-jogada)
    - [Realizar Chamada](#3-realizar-chamada)
    - [Coletar Cartas](#4-coletar-cartas)

---

## Requisitos

- Ruby 3.3.0+
- Rails 7+
- Banco de Dados SQLite

---

## Instalação e Build

1. Clone o repositório do projeto:
   ```sh
   git clone https://github.com/seu-usuario/truco-api.git
   ```
2. Entre no diretório do projeto:
   ```sh
   cd truco-api
   ```
3. Instale as dependências do projeto:
   ```sh
   bundle install
   ```
4. Crie o banco de dados e execute as migrações:
   ```sh
   rails db:create db:migrate
   ```

---

## Como Executar

Para executar o servidor de desenvolvimento:
```sh
rails server
```
Acesse `http://localhost:3000` no navegador para interagir com a API.

---

## Rotas da API

### Jogadores

#### 1. Listar Jogadores
- **Endpoint:** `GET /players`
- **Descrição:** Retorna uma lista paginada de jogadores.
- **Parâmetros de Query (opcionais):**
  - `page` (inteiro): O número da página.
  - `per_page` (inteiro): Número de jogadores por página (padrão: 10).

#### 2. Criar Jogador
- **Endpoint:** `POST /players`
- **Descrição:** Cria um novo jogador.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "player": {
      "name": "Nome do Jogador"
    }
  }
  ```

#### 3. Validar Jogador
- **Endpoint:** `GET /players/valid`
- **Descrição:** Valida um jogador com base no UUID e nome fornecidos nos headers.

---

### Salas

#### 1. Listar Salas
- **Endpoint:** `GET /rooms`
- **Descrição:** Retorna uma lista paginada de salas.

#### 2. Criar Sala
- **Endpoint:** `POST /rooms`
- **Descrição:** Cria uma nova sala.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "player_uuid": "uuid-do-jogador",
    "room": {
      "name": "Nome da Sala"
    }
  }
  ```

#### 3. Entrar em uma Sala
- **Endpoint:** `POST /rooms/:uuid/join`
- **Descrição:** Permite que um jogador entre em uma sala.

#### 4. Sair de uma Sala
- **Endpoint:** `POST /rooms/:uuid/leave`
- **Descrição:** Permite que um jogador saia de uma sala.

#### 5. Alterar Cadeira
- **Endpoint:** `POST /rooms/:uuid/changechair`
- **Descrição:** Permite que um jogador altere sua posição na sala.

#### 6. Expulsar Jogador
- **Endpoint:** `POST /rooms/:uuid/kick`
- **Descrição:** O dono da sala pode expulsar um jogador.

#### 7. Alterar Status de Pronto
- **Endpoint:** `POST /rooms/:uuid/ready/:boolean`
- **Descrição:** Altera o status de pronto de um jogador.

#### 8. Iniciar Partida
- **Endpoint:** `POST /rooms/:uuid/start`
- **Descrição:** Inicia a partida, caso os jogadores estejam prontos.

---

### Jogos

#### 1. Exibir Jogo
- **Endpoint:** `GET /games/:uuid`
- **Descrição:** Exibe detalhes do jogo, incluindo cartas e status.

#### 2. Fazer Jogada
- **Endpoint:** `POST /games/:uuid/play_move`
- **Descrição:** Permite que um jogador faça uma jogada.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "card": "valor-da-carta"
  }
  ```

#### 3. Realizar Chamada
- **Endpoint:** `POST /games/:uuid/call`
- **Descrição:** Realiza uma chamada no jogo (Truco, 6, 9, ou 12).

#### 4. Coletar Cartas
- **Endpoint:** `POST /games/:uuid/collect`
- **Descrição:** Permite recolher cartas após uma rodada.
