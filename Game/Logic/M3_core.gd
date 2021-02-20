extends Node

# размерность матрицы игрового поля(квадратная)
const n_cols = 10
const n_rows = 10
# массив клеток игрового поля
var fields_model = []
# типы клеток
enum e_fields_types{
	# динамические
	EFT_RED = 1, 
	EFT_GREEN, 
	EFT_BLUE, 
	EFT_YELLOW, 
	EFT_EMPTY,
	EFT_ERROR,
	# статические
	EFT_HOLE, 
	EFT_ROCK, 
	EFT_SAND, 
	# наградные
	EFT_M3, 
	EFT_M4,
	EFT_M5, 
	EFT_M6, 
	EFT_M7
}
var a_empty_cells = []
# указатель на функцию в скрипте сцены отвечающий за обработку матчей
var pf_match_clb = null
# указатель на функцию в скрипте сцены отвечающий за обмен типами клеток
var pf_swap_clb = null
# указатель на функцию в скрипте сцены отвечающий за создание клеток
var pf_create_clb = null
# указатель на функцию в скрипте сцены отвечающий за отображение подсказок
var pf_hint_clb = null
# указатель на функцию в скрипте сцены отвечающий за отображение очков
var pf_set_points_clb = null
# указатель на функцию в скрипте сцены отвечающий за отображение ограничения по времени
var pf_set_timeout_clb = null
# 2 - поиск пересечений 3 и более последовательных клеток
# 1 - поиск пересечений 2 и более последовательных клеток, находит пересечения 2 х 2х
const n_cross_match_len = 2
var timer = null
const timer_wait_time = 0.2
enum e_shift_direction{
	TOP, 
	LEFT, 
	RIGHT, 
	BOTTOM}
var shift_direction = e_shift_direction.TOP
var points_counter = 0

onready var timer_session = Timer.new()
const timer_session_wait_time = 1
# 3 минуты
const scene_timeout = 180
var scene_start_time = 0

func is_type_static(idx):
	return fields_model[idx] > e_fields_types.EFT_ERROR && fields_model[idx] < e_fields_types.EFT_M3
	
func is_type_dinamic(idx):
	return fields_model[idx] > e_fields_types.EFT_M3 || fields_model[idx] < e_fields_types.EFT_EMPTY
	
# можем получить сгнал о готовности дерева после родителя!
func _ready():
	timer_session.connect("timeout",self,"_on_timer_session_timeout")
	timer_session.set_wait_time( timer_session_wait_time )
	add_child(timer_session)
	timer_session.start()
	scene_start_time = OS.get_unix_time()

func init():
	randomize()
	if timer == null:
		timer = Timer.new()
		timer.connect("timeout",self,"_on_timer_timeout")
		timer.set_wait_time( timer_wait_time )
		add_child(timer)
	fields_model.clear()
	print(e_fields_types)
	for ind in n_cols * n_rows:
		# тип должен указывать на элемент следующий за последним, чтобы можно было брать значение по модулю в пределах полей.
		var type = int(rand_range(e_fields_types.EFT_RED,e_fields_types.EFT_EMPTY))
		fields_model.append(type)

func get_auto_start_positions():
	while true:
		var matches = find_matches()
		if !matches.empty():
			a_empty_cells.clear()
			for match_inds in matches:
				a_empty_cells += match_inds
				for ind in match_inds:
					fields_model[ind] = e_fields_types.EFT_EMPTY
			a_empty_cells.sort()
			for ind in range(a_empty_cells.size() - 1):
				if a_empty_cells[ind] == a_empty_cells[ind + 1]:
					a_empty_cells[ind] = -1
			
			while 	true:
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
									var type = int(rand_range(e_fields_types.EFT_RED,e_fields_types.EFT_EMPTY))
									# заменили старий тип в модели на новый
									fields_model[a_empty_cells[ind]] = type
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
									# в массиве пустых клеток меняем значение индекса на индекс клетки сверху
									a_empty_cells[ind] = top_ind
				if is_proc == false:
					break
		else:
			return

func get_type_from_pos(x, y):
	if x >= 0 && x <= n_cols - 1 && y >= 0 && y <= n_rows - 1:
		return fields_model[y * n_cols + x]
	else:
		return e_fields_types.EFT_ERROR

func get_ind_from_pos(x:int, y:int):
	return y * n_cols + x
	
func get_ind_from_pos2(pos:Vector2):
	return get_ind_from_pos(pos.x,pos. y)
	
func get_pos_from_ind(index):
	return Vector2(index % n_cols, index / n_rows)

# найти возможный матч
func find_all_potential_matches():
	for x in n_cols:
		for y in n_rows:
			var cur_type = get_type_from_pos(x, y)
			if is_type_static(get_ind_from_pos(x, y)):
				continue
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
	if is_type_static(first_index) || is_type_static(second_index):
		return
	
	var type_min = min(fields_model[first_index], fields_model[second_index])
	var type_max = max(fields_model[first_index], fields_model[second_index])
	
	# свап с наградой
	if (type_min > e_fields_types.EFT_M3 && type_max > e_fields_types.EFT_M3) \
	|| (type_min < e_fields_types.EFT_EMPTY && type_max > e_fields_types.EFT_M3):
		match_awards([[first_index, second_index]])
		return
	
	var tmp = fields_model[first_index]
	fields_model[first_index] = fields_model[second_index]
	fields_model[second_index] = tmp
	
	var matches = find_matches()
	if pf_swap_clb && !matches.empty():
		pf_swap_clb.call_func(first_index, second_index)
		for matched in matches:
			if first_index in matched:
				match_awards(matches, first_index)
				break
			if second_index in matched:
				match_awards(matches, second_index)
				break
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
			if is_type_static(get_ind_from_pos(x, y)):
				continue
			# несколько последовательно расположенных клеток с одинаковым типом
			# пропускаем всё что не кристаллы
			if cur_type == last_type && cur_type < e_fields_types.EFT_EMPTY:
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
			if is_type_static(get_ind_from_pos(x, y)):
				continue
			# несколько последовательно расположенных клеток с одинаковым типом
			if cur_type == last_type && cur_type < e_fields_types.EFT_EMPTY:
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
				match_inds.sort()
				for i in range(match_inds.size() - 1, -1, -1):
						if i > 0 && match_inds[i - 1] == match_inds[i]:
							match_inds.remove(i)
				multi_match_inds.append(match_inds)
	return multi_match_inds

# ищем совпадения по всему игровому полю.
func find_all_matches():
	match_awards(find_matches())

func get_reward_type_array(idx):
	var pos = get_pos_from_ind(idx)
	var ret = []
	match fields_model[idx]:
		e_fields_types.EFT_M4:
			for vert in n_rows:
				if get_type_from_pos(pos.x, vert) != e_fields_types.EFT_ERROR && !is_type_static(get_ind_from_pos(pos.x, vert)):
					ret.append(get_ind_from_pos(pos.x, vert))
		e_fields_types.EFT_M5:
			for vert in n_rows:
				if get_type_from_pos(pos.x, vert) != e_fields_types.EFT_ERROR && !is_type_static(get_ind_from_pos(pos.x, vert)):
					ret.append(get_ind_from_pos(pos.x, vert))
			for hor in n_cols:
				if (get_type_from_pos(hor, pos.y)) != e_fields_types.EFT_ERROR && !is_type_static(get_ind_from_pos(hor, pos.y)):
					ret.append(get_ind_from_pos(hor, pos.y))
		e_fields_types.EFT_M6:
			pos += Vector2(-1, -1)
			for vert in 3:
				for hor in 3:
					if (get_type_from_pos(pos.x + hor, pos.y + vert)) != e_fields_types.EFT_ERROR && !is_type_static(get_ind_from_pos(pos.x + hor, pos.y + vert)):
						ret.append(get_ind_from_pos(pos.x + hor, pos.y + vert))
		e_fields_types.EFT_M7:
			for idx in n_rows * n_cols:
				ret.append(idx)
	return ret

# выдаём награду за совпадение(очки, подсказки).
func match_awards(multi_match_inds, position = null):
	if pf_match_clb && !multi_match_inds.empty():
		pf_match_clb.call_func(multi_match_inds)
	else:
		return
	
	# удаляем индексы совпавших клеток из основного массива
	a_empty_cells.clear()
	for match_inds in multi_match_inds:
		# количество совпадений
		var reward_cell_type = e_fields_types.EFT_M3
		match match_inds.size():
			2:
				var type_min = min(fields_model[match_inds[0]], fields_model[match_inds[1]])
				var type_max = max(fields_model[match_inds[0]], fields_model[match_inds[1]])
				# свап двух награх
				if (type_min > e_fields_types.EFT_M3 && type_max > e_fields_types.EFT_M3):
					# свап двух одноуровневых наград
					if type_min == type_max && type_min < e_fields_types.EFT_M7:
						# увеличиваем на уровень результирующий ревард в позицию куда матчили
						fields_model[match_inds[1]] = type_min + 1
						# даём награду на слияние ревардов
						points_counter += (type_max +  type_min) * 2 
						# удаляем результирующий ревард из списка сматченых
						pf_create_clb.call_func(match_inds[1], type_min + 1)
						match_inds.remove(1)
					# свап разноуровневых ревардов
					else:
						# в позицию где должен рвануть ревар(куда матчим) устанавливаем максимальный тип
						fields_model[match_inds[1]] = type_max
						# получим массив индексов ячеек которые подрывает ревард и добавим в массив сматченных для удаления
						var match_inds_rew = get_reward_type_array(match_inds[1])
						if pf_match_clb && !match_inds_rew.empty():
							pf_match_clb.call_func([match_inds_rew])
						points_counter += (type_max +  type_min) * 2 * match_inds_rew.size()
						match_inds += match_inds_rew
						
				# свап награды и кристалла
				if type_min < e_fields_types.EFT_EMPTY && type_max > e_fields_types.EFT_M3:
					fields_model[match_inds[1]] = type_max
					# получим массив индексов ячеек которые подрывает ревард и добавим в массив сматченных для удаления
					var match_inds_rew = get_reward_type_array(match_inds[1])
					if pf_match_clb && !match_inds_rew.empty():
							pf_match_clb.call_func([match_inds_rew])
					points_counter += (type_max +  type_min) * 2 * match_inds_rew.size()
					match_inds += match_inds_rew
			3:
				points_counter += match_inds.size()
			4:
				points_counter += match_inds.size() * 2
				reward_cell_type =  e_fields_types.EFT_M4
			5:
				points_counter += match_inds.size() * 3
				reward_cell_type =  e_fields_types.EFT_M5
			6:
				points_counter += match_inds.size() * 4
				reward_cell_type =  e_fields_types.EFT_M6
			7:
				points_counter += match_inds.size() * 5
				reward_cell_type =  e_fields_types.EFT_M7
				
		if pf_set_points_clb:
			pf_set_points_clb.call_func(points_counter)
			
		if reward_cell_type > e_fields_types.EFT_M3:
			match_inds.sort()
			var idx = match_inds.find(position)
			if idx == -1:
				idx = match_inds.size() / 2
			# позиционируем награду в свап который привёл к матчу
			if idx > -1:
				fields_model[match_inds[idx]] = reward_cell_type
				pf_create_clb.call_func(match_inds[idx], reward_cell_type)
				match_inds.remove(idx)
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
						var type = int(rand_range(e_fields_types.EFT_RED,e_fields_types.EFT_EMPTY))
						# заменили старий тип в модели на новый
						fields_model[a_empty_cells[ind]] = type
						# вызвали метод из представления отвечающий за визуализацию создания новой клетки с новым типом
						pf_create_clb.call_func(a_empty_cells[ind], type)
						# удаляем из обрабатываемого массива пустых клеток - созданную
						a_empty_cells[ind] = -1
					else:
						# позиция выше с которой перемещаем клетку
						var cur_pos = get_pos_from_ind(a_empty_cells[ind])
						var top_idx = get_ind_from_pos2(cur_pos + Vector2(0, -1))
						var left_idx = get_ind_from_pos2(cur_pos + Vector2(-1, -1))
						var right_idx = get_ind_from_pos2(cur_pos + Vector2(1, -1))
						var from_ind = null
						if fields_model[top_idx] == e_fields_types.EFT_EMPTY:
							continue
						if a_empty_cells.has(top_idx) || is_type_static(top_idx) || fields_model[top_idx] == e_fields_types.EFT_EMPTY:
							if a_empty_cells.has(left_idx) || is_type_static(left_idx) || fields_model[left_idx] == e_fields_types.EFT_EMPTY:
								if a_empty_cells.has(right_idx) || is_type_static(right_idx) || fields_model[right_idx] == e_fields_types.EFT_EMPTY:
									a_empty_cells[ind] = -1
									continue
								else:
									from_ind = right_idx
							else:
								from_ind = left_idx
						else:
							from_ind = top_idx
						
						# тип перемещаемой сверху клетки
						var bt_type = fields_model[a_empty_cells[ind]]
						# меняем типы клеток
						fields_model[a_empty_cells[ind]] = fields_model[from_ind]
						fields_model[from_ind] = bt_type
						# просим представление обменять клетки
						pf_swap_clb.call_func(from_ind, a_empty_cells[ind])
						# в массиве пустых клеток меняем значение индекса на индекс клетки сверху
						a_empty_cells[ind] = from_ind
	if is_proc == false:
		timer.stop()
		# после матча и смещения ячеек проверяем что не появилось новых матчей
		find_all_matches()

func _on_timer_session_timeout():
	var time_elapsed = scene_timeout - (OS.get_unix_time() - scene_start_time)
	if time_elapsed >= 0 && pf_set_timeout_clb:
		pf_set_timeout_clb.call_func(g_helper_mgr.format_timestamp_to_str(time_elapsed, g_helper_mgr.FORMAT_MINUTES | g_helper_mgr.FORMAT_SECONDS))

func set_cell(idx, type):
	if type in e_fields_types.values() && idx < n_cols * n_rows && idx > -1:
		pf_match_clb.call_func([[idx]])
		fields_model[idx] = type
		pf_create_clb.call_func(idx, type)
		
