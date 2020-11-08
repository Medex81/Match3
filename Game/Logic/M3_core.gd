extends Node

var n_cols = 10
var fields_model = []
enum e_fields_types{EFT_RED, EFT_GREEN, EFT_BLUE, EFT_YELLOW, EFT_EMPTY, EFT_ROCK, EFT_SAND, EFT_M3, EFT_M4, EFT_M5, EFT_M6}
var a_cols = []
var a_rows = []

func init():
	randomize()
	# вспомогательные массивы столбцов и строк для быстрой проверки совпадений
	a_cols.resize(n_cols)
	a_rows.resize(n_cols)
	for i in n_cols:
		a_cols[i] = []
		a_cols[i].resize(n_cols)
		a_rows[i] = []
		a_rows[i].resize(n_cols)
	for ind in n_cols * n_cols:
		# тип должен указывать на элемент следующий за последним, чтобы можно было брать значение по модулю в пределах полей. 
		var type = randi() % (e_fields_types.EFT_EMPTY)
		fields_model.append(type)
		a_cols[ind % n_cols][ind / n_cols] = ind
		a_rows[ind / n_cols][ind % n_cols] = ind
		
func find_all_potential_matches():
	if fields_model.empty() == false:
		if find_potential_matches(n_cols):
			return
		if find_potential_matches(a_rows):
			return
		
# ищем потенциальные совпадения.
func find_potential_matches(a_rapid_array):
	# проходим по стобцам и строкам и ищем клетки с одним типом встречающиеся 2 раза подряд или через клетку.	
	for i in a_rapid_array:
		var ret = find_potential_match_in_line(a_rapid_array[i])
		if ret != null:
			match ret.size():
				1: # проверить на столбик левее и правее(если есть)
					# проверить левый столбик
					if i > 0 && fields_model[a_rapid_array[i - 1][ret[0] + 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i - 1][ret[0] + 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
					# проверить правый столбик
					if i < n_cols - 1 && fields_model[a_rapid_array[i + 1][ret[0] + 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i + 1][ret[0] + 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
				2: # показать подсказку
					show_potential_hint([fields_model[a_rapid_array[i][ret[0]]], fields_model[a_rapid_array[i][ret[1]]]])
					return true
				3: # проверка потенциального матча сзади
					# проверить левый столбик
					if i > 0 && fields_model[a_rapid_array[i - 1][ret[0] - 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i - 1][ret[0] - 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
					# проверить правый столбик
					if i < n_cols - 1 && fields_model[a_rapid_array[i + 1][ret[0] - 1]] == fields_model[a_rapid_array[i][ret[0]]]:
						show_potential_hint([fields_model[a_rapid_array[i + 1][ret[0] - 1]], fields_model[a_rapid_array[i][ret[0]]]])
						return true
	return false
# анимация подсказки на двух клетках о потенциальном матче
func show_potential_hint(a_inds):
	pass
	
# массив индексов потенциально совпавших элементов в общем массиве.
func find_potential_match_in_line(line_array):
	# найти последовательность одинаковых значений из 2 элементов подряд или через один.
	for i in n_cols - 3:
		# ++-+
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 3]]:
			return [i + 2, i + 3]
		# +-++
		if fields_model[line_array[i]] != fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 2]] && fields_model[line_array[i]] == fields_model[line_array[i + 3]]:
			return [i, i + 1]
		#  ?
		# +-+
		#  ?
		if fields_model[line_array[i]] != fields_model[line_array[i + 1]] && fields_model[line_array[i]] == fields_model[line_array[i + 2]]:
			return [i]
		#   ?
		# ++-
		#   ?
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && i + 2 < n_cols:
			return [i]
		# ?
		# -++
		# ?
		if fields_model[line_array[i]] == fields_model[line_array[i + 1]] && i > 0:
			return [i , 0, 0]
	return null

# ищем совпадения по всему игровому полю.
func find_all_matches():
	# в цикле получить массив индексов по столбикам и строкам.
	# найти горизонтальные совпадения.
	# найти вертикальные совпадения.
	# найти пересечения вертикальных и горизонтальных совпадений(если есть).
	# вернуть массив массивов с совпадениями.
	pass
	
# выдаём награду за совпадение(очки, подсказки).
func match_awards(matched_inds, field_type):
	pass

# массив индексов совпавших элементов в общем массиве.
func find_match_in_line(line_array):
	# найти непрерывную последовательность одинаковых значений из 3 и более элементов .
	pass

# генерируем новые элементы и двигаем сверху вниз по свободным клеткам.
func shift_from_top():
	# получаем список индексов в которых было совпадение, а значит теперь они пустые.
	# смещаем вниз тип из клетки расположенной выше.
	# если выше статический элемент - пробуем заполнить из бокового столбика, если нет - пропускаем. 
	# если клетка есть, смещаем последовательно до самого верха. в верхнюю клетку добавляем созданный элемент.
	pass
