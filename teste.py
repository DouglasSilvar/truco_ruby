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

def main():
    # Step 1: Create 4 players with random names
    players = []
    for _ in range(4):
        name, uuid = create_player()
        if name and uuid:
            players.append((name, uuid))

    if len(players) < 4:
        print("Failed to create 4 players. Exiting...")
        return

    # Step 2: First player creates a room with a random name
    owner_name, owner_uuid = players[0]
    room_uuid = create_room(owner_name, owner_uuid)
    if not room_uuid:
        print("Failed to create room. Exiting...")
        return

    # Step 3: Other players join the room
    for name, uuid in players[1:]:
        joined = join_room(room_uuid, name, uuid)
        if not joined:
            print(f"Failed to add player '{name}' to the room. Exiting...")
            return

    # Step 4: Set all players as ready
    for name, uuid in players:
        ready = set_ready(room_uuid, name, uuid)
        if not ready:
            print(f"Failed to set player '{name}' as ready. Exiting...")
            return

    # Step 5: Start the game
    started = start_game(room_uuid, owner_name, owner_uuid)
    if started:
        print("The game has been successfully started!")
    else:
        print("Failed to start the game.")

if __name__ == "__main__":
    main()
