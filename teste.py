import requests
import random
import string

BASE_URL = "http://localhost:3000"
HEADERS = {"Content-Type": "application/json"}

def generate_random_name(length=10):
    return ''.join(random.choices(string.ascii_letters, k=length))

def create_player():
    name = generate_random_name()
    response = requests.post(f"{BASE_URL}/players", json={"player": {"name": name}}, headers=HEADERS)
    if response.status_code == 201:
        player_data = response.json()
        print(f"Player '{name}' created successfully:", player_data)
        return player_data['name'], player_data['player_id']
    else:
        print(f"Failed to create player '{name}':", response.json())
        return None, None

def create_room(owner_name, owner_uuid):
    room_name = generate_random_name()
    headers = {**HEADERS, "name": owner_name, "uuid": owner_uuid}
    response = requests.post(
        f"{BASE_URL}/rooms",
        headers=headers,
        json={
            "player_uuid": owner_uuid,
            "room": {
                "name": room_name
            }
        }
    )
    if response.status_code == 201:
        room_data = response.json()
        print("Room created successfully:", room_data)
        return room_data['uuid']
    else:
        print("Failed to create room:", response.json())
        return None

def join_room(room_uuid, player_name, player_uuid):
    headers = {**HEADERS, "name": player_name, "uuid": player_uuid}
    response = requests.post(
        f"{BASE_URL}/rooms/{room_uuid}/join",
        headers=headers,
        json={"player_uuid": player_uuid}
    )
    if response.status_code == 200:
        print(f"Player '{player_name}' joined the room successfully.")
        return True
    else:
        print(f"Failed to add player '{player_name}' to the room:", response.json())
        return False

def set_ready(room_uuid, player_name, player_uuid):
    headers = {**HEADERS, "name": player_name, "uuid": player_uuid}
    response = requests.post(f"{BASE_URL}/rooms/{room_uuid}/ready/true", headers=headers)
    if response.status_code == 200:
        print(f"Player '{player_name}' is now ready.")
        return True
    else:
        print(f"Failed to set player '{player_name}' as ready:", response.json())
        return False
    
def start_game(room_uuid, owner_name, owner_uuid):
    headers = {**HEADERS, "name": owner_name, "uuid": owner_uuid}
    response = requests.post(f"{BASE_URL}/rooms/{room_uuid}/start", headers=headers)
    if response.status_code == 200:
        print("Game started successfully:", response.json())
        return True
    else:
        print("Failed to start the game:", response.json())
        return False

def start_game(room_uuid, owner_name, owner_uuid):
    headers = {**HEADERS, "name": owner_name, "uuid": owner_uuid}
    response = requests.post(f"{BASE_URL}/rooms/{room_uuid}/start", headers=headers)
    if response.status_code == 200:
        game_data = response.json()
        print("Game started successfully:", game_data)
        return game_data["game_id"], game_data["step_id"]
    else:
        print("Failed to start the game:", response.json())
        return None, None

def get_game_info(game_id, player_name, player_uuid):
    headers = {**HEADERS, "name": player_name, "uuid": player_uuid}
    response = requests.get(f"{BASE_URL}/games/{game_id}", headers=headers)
    if response.status_code == 200:
        game_info = response.json()
        # Identifica as cartas do player específico com base na cadeira
        chairs = game_info["chairs"]
        step = game_info["step"]
        
        # Determina a cadeira do jogador e pega as cartas
        chair_cards = {
            "chair_a": step["cards_chair_a"],
            "chair_b": step["cards_chair_b"],
            "chair_c": step["cards_chair_c"],
            "chair_d": step["cards_chair_d"]
        }
        
        # Identifica a cadeira do jogador e armazena as cartas
        player_chair = next((chair for chair, player in chairs.items() if player == player_name), None)
        player_cards = chair_cards.get(player_chair, [])
        
        print(f"Player: {player_name} Chair: {player_chair} Cards: {player_cards}")
        return player_name, player_chair, player_cards
    else:
        print(f"Failed to get game info for player '{player_name}':", response.json())
        return None, None, None
    
def play_move(game_id, player_name, player_uuid, card):
    headers = {**HEADERS, "name": player_name, "uuid": player_uuid}
    response = requests.post(
        f"{BASE_URL}/games/{game_id}/play_move",
        headers=headers,
        json={"card": card}
    )
    if response.status_code == 200:
        print(f"Player '{player_name}' played card: {card}")
        return True
    else:
        print(f"Failed to play card '{card}' for player '{player_name}':", response.json())
        return False

def take_turns(game_id, players_cards):
    remaining_players = {name: cards for name, _, cards in players_cards if cards}  # Players with cards to play
    vira_card = None

    while remaining_players:
        for name, uuid, cards in players_cards:
            if name not in remaining_players:
                continue  # Skip players who have already played
            
            headers = {**HEADERS, "name": name, "uuid": uuid}
            response = requests.get(f"{BASE_URL}/games/{game_id}", headers=headers)
            if response.status_code == 200:
                game_info = response.json()
                player_time = game_info["step"]["player_time"]
                vira_card = game_info["step"]["vira"]  # Obtém o valor da "vira"
                
                # Verifica se é a vez do player atual e se ainda não jogou
                if player_time == name and cards:
                    # Seleciona a primeira carta disponível para jogar
                    card_to_play = cards.pop(0)
                    # Joga a carta
                    play_success = play_move(game_id, name, uuid, card_to_play)
                    if play_success:
                        # Remove o jogador da lista de verificações se jogou
                        remaining_players.pop(name, None)
            else:
                print(f"Failed to get game info for player '{name}':", response.json())
                return

    # Print final com a carta "vira"
    if vira_card:
        print(f"The 'vira' card is: {vira_card}")

    # GET final para obter o time vencedor
    headers = {**HEADERS, "name": name, "uuid": uuid}
    response = requests.get(f"{BASE_URL}/games/{game_id}", headers=headers)
    if response.status_code == 200:
        game_info = response.json()
        winner_team = game_info["step"]["first"]
        print(f"The winning team for this round is: {winner_team}")
    else:
        print("Failed to get the winning team:", response.json())

def main():
    # Criação de players e sala, similar ao código original
    players = []
    for _ in range(4):
        name, uuid = create_player()
        if name and uuid:
            players.append((name, uuid))

    if len(players) < 4:
        print("Failed to create 4 players. Exiting...")
        return

    owner_name, owner_uuid = players[0]
    room_uuid = create_room(owner_name, owner_uuid)
    if not room_uuid:
        print("Failed to create room. Exiting...")
        return

    for name, uuid in players[1:]:
        joined = join_room(room_uuid, name, uuid)
        if not joined:
            print(f"Failed to add player '{name}' to the room. Exiting...")
            return

    for name, uuid in players:
        ready = set_ready(room_uuid, name, uuid)
        if not ready:
            print(f"Failed to set player '{name}' as ready. Exiting...")
            return

    game_id, step_id = start_game(room_uuid, owner_name, owner_uuid)
    if not game_id or not step_id:
        print("Failed to start the game.")
        return

    # Cada player faz o GET inicial para obter suas cartas
    players_cards = []
    for name, uuid in players:
        _, player_chair, player_cards = get_game_info(game_id, name, uuid)
        players_cards.append((name, uuid, player_cards))

    # Cada player verifica se é sua vez e joga uma carta
    take_turns(game_id, players_cards)

if __name__ == "__main__":
    main()