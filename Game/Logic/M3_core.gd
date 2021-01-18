extends Node

# размерность матрицы игрового поля(квадратная)
const n_cols = 10
const n_rows = 10
# массив клеток игрового поля
var fields_model = []
# типы клеток
enum e_fields_types{EFT_RED, EFT_GREEN, EFT_BLUE, EFT_YELLOW, EFT_EMPTY, EFT_ERROR, EFT_ROCK, EFT_SAND, EFT_M3, EFT_M4, EFT_M5, EFT_M6}
var a_empty_cells = []
# указатель на функцию в скрипте сцены отвечающий за обработку матчей
var pf_match_clb = null
# указатель на функцию в скрипте сцены отвечающий за обмен типами клеток
var pf_swap_clb = null
# указатель на функцию в скрипте сцены отвечающий за создание клеток
var pf_create_clb = null
# указатель на функцию в скрипте сцены отвечающий за отображение подсказок
var pf_hint_clb = null
# 2 - поиск пересечений 3 и более последовательных клеток
# 1 - поиск пересечений 2 и более последовательных клеток, находит пересечения 2 х 2х
const n_cross_match_len = 2
var timer = null
const timer_wait_time = 0.2
enum e_shift_direction{TOP, LEFT, RIGHT, BOTTOM}
var shift_direction = e_shift_direction.TOP

func init():
	randomize()
	for ind in n_cols * n_cols:
		# тип должен указывать на элемент следующий за последним, чтобы можно было брать значение по модулю в пределах полей. 
		var type = randi() % (e_fields_types.EFT_EMPTY)
		fields_model.append(type)
	if timer == null:
		timer = Timer.new()
		timer.connect("timeout",self,"_on_timer_timeout")
		timer.set_wait_time( timer_wait_time )
		add_child(timer)

func get_type_from_pos(x, y):
	if x >= 0 && x <= n_cols - 1 && y >= 0 && y <= n_rows:
		return fields_model[y * n_cols + x]
	else:
		return e_fields_types.EFT_ERROR

func get_ind_from_pos(x, y):
	return y * n_cols + x
	
func get_pos_from_ind(index):
	return Vector2(index % n_cols, index / n_rows)

# найти возможный матч
func find_all_potential_matches():
	for x in n_cols:
		for y in n_rows:
			var cur_type = get_type_from_pos(x, y)
			# на клетку ниже, проверяем окрестность
			if cur_type == get_type_from_pos(x, y + 1):
				# в
				if cur_type == get_type_from_pos(x, y - 2):
					show_potential_hint(get_ind_from_pos(x, y - 1), get_ind_from_pos(x, y - 2))
					return
				# вп
				if cur_type == get_type_from_pos(x + 1, y - 1):
					show_potential_hint(get_ind_from_pos(x, y - 1), get_ind_from_pos(x + 1, y - 1))
					return
				# вл
				if cur_type == get_type_from_pos(x - 1, y - 1):
					show_potential_hint(get_ind_from_pos(x, y - 1), get_ind_from_pos(x - 1, y - 1))
					return
				# н
				if cur_type == get_type_from_pos(x, y + 3):
					show_potential_hint(get_ind_from_pos(x, y + 2), get_ind_from_pos(x, y + 3))
					return
				# нп
				if cur_type == get_type_from_pos(x + 1, y + 2):
					show_potential_hint(get_ind_from_pos(x, y + 2), get_ind_from_pos(x + 1, y + 2))
					return
				# нл
				if cur_type == get_type_from_pos(x - 1, y + 2):
					show_potential_hint(get_ind_from_pos(x, y + 2), get_ind_from_pos(x - 1, y + 2))
					return
			# на клетку вправо, проверяем окрестность
			if cur_type == get_type_from_pos(x + 1, y):
				# л
				if cur_type == get_type_from_pos(x - 2, y):
					show_potential_hint(get_ind_from_pos(x - 1, y), get_ind_from_pos(x - 2, y))
					return
				# лв
				if cur_type == get_type_from_pos(x - 1, y - 1):
					show_potential_hint(get_ind_from_pos(x - 1, y), get_ind_from_pos(x - 1, y - 1))
					return
				# лн
				if cur_type == get_type_from_pos(x - 1, y + 1):
					show_potential_hint(get_ind_from_pos(x - 1, y), get_ind_from_pos(x - 1, y + 1))
					return
				# п
				if cur_type == get_type_from_pos(x + 3, y):
					show_potential_hint(get_ind_from_pos(x + 2, y), get_ind_from_pos(x + 3, y))
					return
				# пн
				if cur_type == get_type_from_pos(x + 2, y + 1):
					show_potential_hint(get_ind_from_pos(x + 2, y), get_ind_from_pos(x + 2, y + 1))
					return
				# пв
				if cur_type == get_type_from_pos(x + 2, y - 1):
					show_potential_hint(get_ind_from_pos(x + 2, y), get_ind_from_pos(x + 2, y - 1))
					return
			# через клетку вниз, проверяем окрестность
			if cur_type == get_type_from_pos(x, y + 2):
				# л
				if cur_type == get_type_from_pos(x - 1, y + 1):
					show_potential_hint(get_ind_from_pos(x, y + 1), get_ind_from_pos(x - 1, y + 1))
					return
				# п
				if cur_type == get_type_from_pos(x + 1, y + 1):
					show_potential_hint(get_ind_from_pos(x, y + 1), get_ind_from_pos(x + 1, y + 1))
					return
			# через клетку вправо, проверяем окрестность
			if cur_type == get_type_from_pos(x + 2, y):
				# в
				if cur_type == get_type_from_pos(x + 1, y - 1):
					show_potential_hint(get_ind_from_pos(x + 1, y), get_ind_from_pos(x + 1, y - 1))
					return
				# н
				if cur_type == get_type_from_pos(x + 1, y + 1):
					show_potential_hint(get_ind_from_pos(x + 1, y), get_ind_from_pos(x + 1, y + 1))
					return

# анимация подсказки на двух клетках о потенциальном матче
func show_potential_hint(from_ind, to_ind):
	if pf_hint_clb != null:
		pf_hint_clb.call_func(from_ind, to_ind)

# проверить, что ячейки смежные
func is_near(first_index, second_index):	
	var first_pos = get_pos_from_ind(first_index)
	var second_pos = get_pos_from_ind(second_index)
	if first_pos + Vector2(-1, 0) == second_pos || first_pos + Vector2(+1, 0) == second_pos || first_pos + Vector2(0, -1) == second_pos || first_pos + Vector2(0, +1) == second_pos:
		return true
	return false

# проверить, что после обмена ячеек появился матч
func check_swap_cells(first_index, second_index):
	var tmp = fields_model[first_index]
	fields_model[first_index] = fields_model[second_index]
	fields_model[second_index] = tmp	
	var matches = find_matches()
	if pf_swap_clb && !matches.empty():
		pf_swap_clb.call_func(first_index, second_index)
		match_awards(matches)
	# матча нет - вернуть назад
	else:
		tmp = fields_model[second_index]
		fields_model[second_index] = fields_model[first_index]
		fields_model[first_index] = tmp
	
func find_matches():
	var raw_matches = {}
	for x in n_cols:
		# количество совпадений текущего типа
		var cur_count = 1
		var last_type = get_type_from_pos(x, 0)
		var result = [[x, 0]]
		for y in range (1, n_rows):
			var cur_type = get_type_from_pos(x, y)
			# несколько последовательно расположенных клеток с одинаковым типом
			if cur_type == last_type:
				cur_count += 1
				result.append([x, y])
			# конец последовательности текущего типа
			else:
				# берём последовательности от двух подряд потому, что они могут стоять перпендикулярно
				if cur_count > n_cross_match_len:
					# в возращаемом массиве индекс в строке быстрого массива и размер последовательности
					if raw_matches.has(last_type) == false:
						raw_matches[last_type] = []
					raw_matches[last_type].append(result.duplicate())
					
				last_type = cur_type
				cur_count = 1
				result.clear()
				result.append([x, y])
		# последовательность находится в конце
		if cur_count > 1:
			if raw_matches.has(last_type) == false:
				raw_matches[last_type] = []
			raw_matches[last_type].append(result.duplicate())
	
	for y in n_rows:
		# количество совпадений текущего типа
		var cur_count = 1
		var last_type = get_type_from_pos(0, y)
		var result = [[0, y]]
		for x in range (1, n_cols):
			var cur_type = get_type_from_pos(x, y)
			# несколько последовательно расположенных клеток с одинаковым типом
			if cur_type == last_type:
				cur_count += 1
				result.append([x, y])
			# конец последовательности текущего типа
			else:
				# берём последовательности от двух подряд потому, что они могут стоять перпендикулярно
				if cur_count > n_cross_match_len:
					# в возращаемом массиве индекс в строке быстрого массива и размер последовательности
					if raw_matches.has(last_type) == false:
						raw_matches[last_type] = []
					raw_matches[last_type].append(result.duplicate())
					
				last_type = cur_type
				cur_count = 1
				result.clear()
				result.append([x, y])
		# последовательность находится в конце
		if cur_count > 1:
			if raw_matches.has(last_type) == false:
				raw_matches[last_type] = []
			raw_matches[last_type].append(result.duplicate())
	# проходим то совпадениям типов кристаллов
	for key in raw_matches:
		var type_match = raw_matches[key]
		# проходим по всем совпадениям типа кроме последнего (сравниваем со следующим)
		for match_ind in range(type_match.size() - 1):
			# пересекающийся массив стоящий правее добавляем в левый и очищаем его. Проверяем что не входим в очищенный массив
			if type_match[match_ind].empty() == false :
				# проходим по элементам текущего массива и ищем совпадение в массиве справа
				for item in type_match[match_ind]:
					if type_match[match_ind + 1].has(item):
						type_match[match_ind] += type_match[match_ind + 1]
						type_match[match_ind + 1].clear()
	# проходим то совпадениям типов кристаллов совмещённых
	var multi_match_inds = []
	for key in raw_matches:
		var type_match = raw_matches[key]
		# проходим по всем совпадениям типа кроме последнего (сравниваем со следующим)
		for match_arr in type_match:
			# пересекающийся массив стоящий правее добавляем в левый и очищаем его. Проверяем что не входим в очищенный массив
			if match_arr.empty() == false && match_arr.size() > 2:
				var match_inds = []
				for pos in match_arr:
					match_inds.append(get_ind_from_pos(pos[0], pos[1]))
				multi_match_inds.append(match_inds)
	return multi_match_inds

# ищем совпадения по всему игровому полю.
func find_all_matches():
	match_awards(find_matches())

# выдаём награду за совпадение(очки, подсказки).
func match_awards(multi_match_inds):	
	if pf_match_clb && !multi_match_inds.empty():
		pf_match_clb.call_func(multi_match_inds)
	else:
		return
	# количество совпадений
#	match match_inds.size():
#		3:
#			pass
#		4:
#			pass
#		5:
#			pass
#		6:
#			pass
	# удаляем индексы совпавших клеток из основного массива
	a_empty_cells.clear()
	for match_inds in multi_match_inds:
		a_empty_cells += match_inds
		for ind in match_inds:
			fields_model[ind] = e_fields_types.EFT_EMPTY
	
	if timer == null:
		return
	a_empty_cells.sort()
	for ind in range(a_empty_cells.size() - 1):
		if a_empty_cells[ind] == a_empty_cells[ind + 1]:
			a_empty_cells[ind] = -1
	shift_from()

# генерируем новые элементы и двигаем сверху вниз по свободным клеткам.
func shift_from():
	timer.stop()
	timer.start()
# по таймеру будем смещать ячейки в выбранном направлении имитируя падение
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
		# после матча и смещения ячеек проверяем что не появилось новых матчей
		find_all_matches()
