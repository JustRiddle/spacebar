extends Node2D

@export var is_dragging = false
@export var activeScientist = null
@export var baseUrl = "http://127.0.0.1:8000"


func serveDrink(taste: Dictionary) -> Array:
	var dymek := get_tree().current_scene.get_node_or_null("Dymek")
	if not dymek:
		push_error("Nie znaleziono węzła Dymek!")
	dymek.setText("")
	var http := HTTPRequest.new()
	add_child(http)

	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(taste)
	var error := http.request(baseUrl + "/scientist/"+str(activeScientist)+"/serve-drink", headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		push_error("Błąd zapytania: %s" % error)
		http.queue_free()
		return []

	var result = await http.request_completed
	var response_code = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code == 200:
		var response = JSON.parse_string(response_body.get_string_from_utf8())
		if response and response.has("message") and response.has("attempts_granted"):
			var message = response["message"]
			var attempts_granted = response["attempts_granted"]
			http.queue_free()
			dymek.setText(message)
			get_tree().current_scene.start_conversation(attempts_granted)
			return [message, attempts_granted]
		else:
			push_error("Niepoprawna odpowiedź serwera: %s" % response)
	else:
		push_error("Błąd odpowiedzi HTTP: %s" % response_code)
	http.queue_free()
	return []


func reply(conversation: String) -> bool:
	var dymek := get_tree().current_scene.get_node_or_null("Dymek")
	if not dymek:
		push_error("Nie znaleziono węzła Dymek!")
	dymek.setText("")
	var http := HTTPRequest.new()
	add_child(http)

	var headers := ["Content-Type: application/json"]
	var body := '{"message":"'+conversation+'"}'
	var error := http.request(baseUrl + "/scientist/"+str(activeScientist)+"/conversation", headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		push_error("Błąd zapytania: %s" % error)
		http.queue_free()
		return true

	var result = await http.request_completed
	var response_code = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code == 200:
		var response = JSON.parse_string(response_body.get_string_from_utf8())
		if response and response.has("response") and response.has("isOver"):
			var clientResponse = response["response"]
			var isOver = response["isOver"]
			http.queue_free()
			dymek.setText(clientResponse)
			return isOver
		else:
			push_error("Niepoprawna odpowiedź serwera: %s" % response)
	else:
		push_error("Błąd odpowiedzi HTTP: %s" % response_code)
	http.queue_free()
	return true

func newClient() -> void:
	get_tree().current_scene.new_client()
