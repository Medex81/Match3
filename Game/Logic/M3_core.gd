extends Node

# размерность матрицы игрового поля(квадратная)
const n_cols = 10
# массив клеток игрового поля
var fields_model = []
# типы клеток
enum e_fields_types{EFT_RED, EFT_GREEN, EFT_BLUE, EFT_YELLOW, EFT_EMPTY, EFT_ROCK, EFT_SAND, EFT_M3, EFT_M4, EFT_M5, EFT_M6}
# быстрые массивы для перебора клеток по строкам и столбцам
var a_cols = []
var a_rows = []
var a_empty_cells = []
# указатель на функцию в скрипте сцены отвечающий за обработку матчей
var pf_match_clb = null
# указатель на функцию в скрипте сцены отвечающий за обмен типами клеток
var pf_swap_clb = null
# указатель на функцию в скрипте сцены отвечающий за создание клеток
var pf_create_clb = null
# 2 - поиск пересечений 3 и более последовательных клеток
# 1 - поиск пересечений 2 и более последовательных клеток, находит пересечения 2 х 2х
const n_cross_match_len = 2
var timer = null
const timer_wait_time = 0.5
enum e_shift_direction{TOP, LEFT, RIGHT, BOTTOM}
var shift_direction = e_shift_direction.TOP

func init():
	randomize()
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
	if timer == null:
		timer = Timer.new()
		timer.connect("timeout",self,"_on_timer_timeout")
		timer.set_wait_time( timer_wait_time )
		add_child(timer)
		
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
	if fields_model.empty() == false:
		var a_matches = []
		find_matches(a_cols, a_matches)
		find_matches(a_rows, a_matches)
		var multi_matches = []
		if a_matches.empty() == false:
			recursive_additive_matching(a_matches, multi_matches)
		if multi_matches.empty() == false:
			match_awards(multi_matches)
		
# рекурсивно объединяем пересекающиеся массивы
func recursive_additive_matching(src_matches, res_matches):
	res_matches.clear()
	var b_add = false
	# собираем матчи для проверки пересечений
	for ind_curr in range(src_matches.size()):
		if src_matches[ind_curr].empty() == true:
			continue
		var multi_match = []
		multi_match += src_matches[ind_curr]
		for ind_check in range(ind_curr + 1, src_matches.size()):
			for val_curr in src_matches[ind_curr]:
				if src_matches[ind_check].has(val_curr):
					multi_match += src_matches[ind_check]
					src_matches[ind_check].clear()
					b_add = true
					break
		# выбрасываем последовательности из 2х совпадений
		if multi_match.size() > 2:
			res_matches.append(multi_match)
	# в результирующем массиве есть новые объединения
	if res_matches.empty() == false && b_add:
		src_matches = res_matches.duplicate()
		recursive_additive_matching(src_matches, res_matches)

# ищем совпадения
func find_matches(a_rapid_array, matches):
	for item in a_rapid_array:
		# получили массив с совпадениями(если они есть)
		var ret = find_match_in_line(item)
		for match_cells in ret:
			# массив индексов клеток с совпадением
			var arr = []
			# из быстрого массива копируем индексы совпадения
			for ind in range(match_cells[0], match_cells[0] + match_cells[1]):
				# преобразуем индексы быстрого массива в индексы большого массива(игрового поля/модели)
				arr.append(item[ind])
			if arr.empty() == false:
				arr.sort()
				matches.append(arr)
	
# выдаём награду за совпадение(очки, подсказки).
func match_awards(matched_inds):
	if pf_match_clb:
		pf_match_clb.call_func(matched_inds)
	# количество совпадений
	match matched_inds.size():
		3:
			pass
		4:
			pass
		5:
			pass
		6:
			pass
	# удаляем индексы совпавших клеток из основного массива
	a_empty_cells.clear()
	for matched in matched_inds:
		a_empty_cells += matched
		for ind in matched:
			fields_model[ind] = e_fields_types.EFT_EMPTY
	matched_inds.clear()
	if a_empty_cells.empty() == true || timer == null:
		return
	a_empty_cells.sort()
	for ind in range(a_empty_cells.size() - 1):
		if a_empty_cells[ind] == a_empty_cells[ind + 1]:
			a_empty_cells[ind] = -1
	shift_from()
		
# массив индексов совпавших элементов в общем массиве.
func find_match_in_line(line_array):
	# найти непрерывную последовательность одинаковых значений из 3 и более элементов.
	#  массив с результатами
	var ret = []
	# текущий тип
	var walk_type = fields_model[line_array[0]]
	# количество совпадений текущего типа
	var cur_count = 1
	# проходим массив клеток по вертикали или горизонтали
	for i in range (1, n_cols):
		# несколько последовательно расположенных клеток с одинаковым типом
		if walk_type == fields_model[line_array[i]]:
			cur_count += 1
		# конец последовательности текущего типа
		if walk_type != fields_model[line_array[i]]:
			# берём последовательности от двух подряд потому, что они могут стоять перпендикулярно
			if cur_count > n_cross_match_len:
				# в возращаемом массиве индекс в строке быстрого массива и размер последовательности
				ret.append([i - cur_count, cur_count])
			walk_type = fields_model[line_array[i]]
			cur_count = 1
	# последовательность находится в конце
	if cur_count > 1:
		ret.append([n_cols - cur_count, cur_count])
		
	return ret

# генерируем новые элементы и двигаем сверху вниз по свободным клеткам.
func shift_from():
	timer.stop()
	timer.start()
	
func _on_timer_timeout():
	# по какой-то причине не создан обработчик создания клеток на стороне представления
	if pf_create_clb == null:
		return
	# проверяем, что в массиве пустых клеток нет нуждающихся в обработке
	var is_proc = false
	# проходим по массиву пустых клеток и заменяем их на выше расположенные или боковые
	for ind in range(a_empty_cells.size()):
		# клетки для которых уже были сгенерированы типы (в верхнем столбике) помечаем как обработанные (-1)
		if a_empty_cells[ind] != -1:
			# обрабатываем пустые клетки
			is_proc = true
			# сдвиг клетки по указанному направлению
			match shift_direction:
				e_shift_direction.TOP:
					# находимся на верхней строке
					if a_empty_cells[ind] < n_cols:
						# сгенерировали новый тип клетки
						var type = randi() % (e_fields_types.EFT_EMPTY)
						# заменили старий тип в модели на новый
						fields_model[a_empty_cells[ind]] = type
						# вызвали метод из представления отвечающий за визуализацию создания новой клетки с новым типом
						pf_create_clb.call_func(a_empty_cells[ind], type)
						# удаляем из обрабатываемого массива пустых клеток - созданную
						a_empty_cells[ind] = -1
					else:
						# позиция выше с которой перемещаем клетку
						var top_ind = a_empty_cells[ind] - n_cols
						# проверяем, что выше не пустая клетка
						if a_empty_cells.has(top_ind):
							continue
						# тип перемещаемой сверху клетки
						var bt_type = fields_model[top_ind]
						# меняем типы клеток
						fields_model[a_empty_cells[ind]] = fields_model[top_ind]
						fields_model[top_ind] = bt_type
						# просим представление обменять клетки
						pf_swap_clb.call_func(top_ind, a_empty_cells[ind])
						# в массиве пустых клеток меняем значение индекса на индекс клетки сверху
						a_empty_cells[ind] = top_ind
	if is_proc == false:
		timer.stop()
