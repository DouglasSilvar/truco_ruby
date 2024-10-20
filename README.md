# Truco API - Projeto Ruby on Rails

Bem-vindo ao projeto Truco API, uma API desenvolvida em Ruby on Rails para gerenciar salas e jogadores de um jogo de truco.

## Índice
- [Requisitos](#requisitos)
- [Instalação e Build](#instala%C3%A7%C3%A3o-e-build)
- [Como Executar](#como-executar)
- [Rotas da API](#rotas-da-api)
  - [Salas](#salas)
    - [Listar Salas](#1-listar-salas)
    - [Criar Sala](#2-criar-sala)
    - [Entrar em uma Sala](#3-entrar-em-uma-sala)
    - [Sair de uma Sala](#4-sair-de-uma-sala)
  - [Jogadores](#jogadores)
    - [Listar Jogadores](#1-listar-todos-os-jogadores)
    - [Criar Jogador](#2-criar-um-novo-jogador)

## Requisitos

- Ruby 3.3.0+
- Rails 7+
- Banco de Dados SQLite

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

## Como Executar

Para executar o servidor de desenvolvimento:
```sh
rails server
```
Acesse `http://localhost:3000` no navegador para interagir com a API.

## Rotas da API

### Salas

#### 1. Listar Salas
- **Endpoint:** `GET /rooms`
- **Descrição:** Retorna uma lista paginada de salas.
- **Parâmetros de Query (opcionais):**
  - `page` (inteiro): O número da página para a paginação.
  - `per_page` (inteiro): Número de salas por página (padrão é 10).
- **Exemplo de Requisição:**
  ```
  GET /rooms?page=1&per_page=10
  ```
- **Resposta de Sucesso (Status: 200):**
  ```json
  {
    "rooms": [
      {
        "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
        "name": "Sala 1",
        "owner": {
          "player_id": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
          "name": "Jogador 1"
        },
        "players_count": 3
      }
    ],
    "meta": {
      "current_page": 1,
      "next_page": 2,
      "prev_page": null,
      "total_pages": 5,
      "total_count": 50
    }
  }
  ```

#### 2. Criar Sala
- **Endpoint:** `POST /rooms`
- **Descrição:** Cria uma nova sala.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "player_uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
    "room": {
      "name": "Nome da Sala"
    }
  }
  ```
- **Exemplo de Requisição:**
  ```
  POST /rooms
  ```
- **Resposta de Sucesso (Status: 201):**
  ```json
  {
    "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
    "name": "Nome da Sala",
    "owner": {
      "player_id": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
      "name": "Jogador 1"
    },
    "players_count": 1
  }
  ```

#### 3. Entrar em uma Sala
- **Endpoint:** `POST /rooms/:uuid/join`
- **Descrição:** Permite que um jogador entre em uma sala.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "player_uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972"
  }
  ```
- **Exemplo de Requisição:**
  ```
  POST /rooms/b5a2a685-fd0f-4878-a38d-f3df1f412972/join
  ```
- **Resposta de Sucesso (Status: 200):**
  ```json
  {
    "message": "Player joined the room",
    "room": {
      "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
      "players_count": 2
    }
  }
  ```

#### 4. Sair de uma Sala
- **Endpoint:** `POST /rooms/:uuid/leave`
- **Descrição:** Permite que um jogador saia de uma sala.
- **Corpo da Requisição (JSON):**
  ```json
  {
    "player_uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972"
  }
  ```
- **Exemplo de Requisição:**
  ```
  POST /rooms/b5a2a685-fd0f-4878-a38d-f3df1f412972/leave
  ```
- **Resposta de Sucesso (Status: 200):**
  ```json
  {
    "message": "Player left the room",
    "room": {
      "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
      "players_count": 1
    }
  }
  ```

### Jogadores

#### 1. Listar Todos os Jogadores
- **Endpoint:** `GET /players`
- **Descrição:** Lista todos os jogadores cadastrados.
- **Parâmetros de Query (opcionais):**
  - `page` (inteiro): O número da página para a paginação.
  - `per_page` (inteiro): Número de jogadores por página (padrão é 10).
- **Exemplo de Requisição:**
  ```
  GET /players?page=1&per_page=10
  ```
- **Resposta de Sucesso (Status: 200):**
  ```json
  {
    "players": [
      {
        "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
        "name": "Jogador 1"
      },
      {
        "uuid": "1c2a9f85-abd5-457b-9d9e-3d12f61c25b8",
        "name": "Jogador 2"
      }
    ],
    "meta": {
      "current_page": 1,
      "next_page": 2,
      "prev_page": null,
      "total_pages": 5,
      "total_count": 50
    }
  }
  ```

#### 2. Criar um Novo Jogador
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
- **Exemplo de Requisição:**
  ```
  POST /players
  ```
- **Resposta de Sucesso (Status: 201):**
  ```json
  {
    "uuid": "b5a2a685-fd0f-4878-a38d-f3df1f412972",
    "name": "Nome do Jogador"
  }
  ```

