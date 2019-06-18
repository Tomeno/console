var
	excode_speed = 30
	// Adding this to trottle excode execution speeds on the fly -Nadrew

#define FILE_FLAG_SUPER 32

datum/task/var/special_flags = 0 // Special flags to keep the kiddos out.

datum/task/proc/parse()
	if (src.p_type)
		src.master.parse_string(src.code, src)
		return
	src.code = replacetext(src.code,"\t","")
	var/list/goto_array = list()
	var/list/command_list = splittext(src.code, "\n")
	var/counter = 1
	for(var/x in command_list)
		var/list/t1 = splittext(x, ";")
		if ((t1.len >= 2 && t1[1] == "id"))
			goto_array["[t1[2]]"] = counter
		counter++

	counter = 1
	var/rcount = 0
	//src.var_list["semi"] = "\[semi\]"
	//src.var_list["newline"] = "\[newline\]"
	//src.var_list["space"] = "\[space\]"
	while((command_list.len >= counter && (src.master && src.master.sys_stat >= 1)))
		// Changed this to a counter-based loop so the sleep() only fires every x loops.
		// This allows excode to execute faster than one line per-tick.
		// No more useless excode programs. - Nadrew
		rcount++
		if(rcount >= excode_speed)
			rcount = 0
			sleep(1)
		var/list/t1 = splittext(command_list[counter], ";")
		for(var/variable in src.var_list)
			for(var/command_parse in t1)
				var/index = t1.Find(command_parse)
				if(variable == src.var_list[variable]) continue
				if("\[[variable]\]" == "\[semi\]") continue
				if("\[[variable]\]" == "\[space\]") continue
				if("\[[variable]\]" == "\[newline\]") continue
				if("\[[variable]\]" == "\[bracket_l\]")
					command_parse = replacetext(command_parse,"\[bracket_l\]","\[")
					continue
				if("\[[variable]\]" == "\[bracket_r\]")
					command_parse = replacetext(command_parse,"\[bracket_r\]","\]")
					continue
				command_parse = replacetext(command_parse,"\[[variable]\]",src.var_list[variable])
				t1[index] = command_parse
		if (t1.len)
			switch(t1[1])
				if("args")
					if(t1.len != 2)
						src.master.show_message("args: Takes 1 argument.")
					else
						var/variable = ckeyEx(get_data(t1[2]))
						var/list/arguments = var_list["arg"]
						if(!arguments || !arguments.len) var_list[variable] = null
						else
							var/arg_string
							for(var/V in arguments)
								if(arg_string) arg_string += " [arguments[V]]"
								else arg_string = "[arguments[V]]"
							var_list[variable] = arg_string

					counter++

				if("setenv")
					if(t1.len != 3)
						src.master.show_message("setenv: Takes two arguments.")
					else
						var
							var_one = get_data(t1[2])
							var_two = get_data(t1[3])
						var_one = ckeyEx(var_one)
						var_one = replacetext(var_one,";","")
						if(var_two == null)
							if(var_one in master.environment) master.environment -= var_one
						else
							master.environment[var_one] = var_two
					counter++
				if("getenv")
					if(t1.len != 3)
						if(t1.len == 2)
							var/list/envlist = src.master.environment.Copy()
							src.var_list[t1[3]] = envlist

						src.master.show_message("getenv: Takes two arguments.")
					else
						var
							var_one = ckeyEx(get_data(t1[2]))
							var_two = t1[3]
						if(!var_one||!var_two)
							src.master.show_message("getenv: Invalid argument(s) supplied.")
						else
							if(var_one in src.master.environment)
								src.var_list[var_two] = src.master.environment[var_one]
							else
								src.var_list[var_two] = null
					counter++
				if("uppertext")
					if(t1.len != 3)
						src.master.show_message("uppertext: Takes two arguments.")
					else
						var
							var_one = get_data(t1[2])
							var_two = t1[3]
						if(!var_one||!var_two)
							src.master.show_message("uppertext: Invalid argument(s) supplied.")
						else
							var_one = uppertext(var_one)
							src.var_list[var_two] = var_one
					counter++
				if("lowertext")
					if(t1.len != 3)
						src.master.show_message("lowertext: Takes two arguments.")
					else
						var
							var_one = get_data(t1[2])
							var_two = t1[3]
						if(!var_one||!var_two)
							src.master.show_message("lowertext: Invalid argument(s) supplied.")
						else
							var_one = lowertext(var_one)
							src.var_list[var_two] = var_one
					counter++

				if("md5")
					if(t1.len != 3)
						src.master.show_message("md5: Takes two arguments.")
					else
						var
							var_one = get_data(t1[2])
							var_two = t1[3]
						if(!var_one||!var_two)
							src.master.show_message("md5: Invalid argument(s) supplied.")
						else
							var_one = md5(var_one)
							src.var_list[var_two] = var_one
					counter++

				if("ckey")
					if(t1.len != 3)
						src.master.show_message("ckey: Takes two arguments.")
					else
						var
							var_one = get_data(t1[2])
							var_two = t1[3]
						if(!var_one||!var_two)
							src.master.show_message("ckey: Invalid argument(s) supplied.")
						else
							var_one = ckey(var_one)
							src.var_list[var_two] = var_one
					counter++

				if("sndsrc")					
					if(t1.len < 3)
						src.master.show_message("sndsrc: Takes at least two arguments.")
					else
						var/mode = "source"
						if(t1.len >= 4)
							mode = get_data(t1[4])
						if(!mode) mode = "source"
						var/datum/file/normal/sound/snd = src.master.parse2file(get_data(t1[3]))
						if(!istype(snd,/datum/file/normal/sound))
							src.master.show_message("Invalid file type")
						else
							switch(mode)
								if("source")
									src.var_list["[t1[2]]"] = snd.s_source
								if("data")
									src.var_list["[t1[2]]"] = snd.text

					counter++


				if("echo_var")
					if(t1.len >= 2)
						var/variable = get_data(t1[2])
						src.master.show_message("[variable]")
					counter++

				if("comment")
					counter++

				if("id")
					counter++

				if("rand")
					if(t1.len < 4)
						src.master.show_message("rand requires three arguments")
					else
						var
							l_bound = text2num(get_data(t1[2]))
							h_bound = text2num(get_data(t1[3]))
							variable = t1[4]
							result = rand(l_bound,h_bound)
						src.var_list["[variable]"] = "[result]"
					counter++

				if("goto")
					if (t1.len >= 2)
						if (text2num(goto_array["[t1[2]]"]) > 0)
							sleep(1)
							counter = text2num(goto_array["[t1[2]]"])

				if("length")
					var/temp = findtext(t1[2], ":", 1, null)
					if (!( temp ))
						if (istype(src.var_list["[t1[2]]"], /list))
							del(src.var_list["[t1[2]]"])
						var/data = src.get_data(t1[3])
						if (istype(data, /list))
							var/L = data
							var/count = 1
							while(L["[count]"] != null)
								count++
							if ((count == 1 && L["1"] == null))
								count = null
							data = count
						else
							data = length(data)
						src.var_list["[t1[2]]"] = data
					else
						if (istype(src.var_list["[copytext(t1[2], 1, temp)]"], /list))
							var/L = src.var_list["[copytext(t1[2], 1, temp)]"]
							var/data = get_data(t1[3])
							if (istype(data, /list))
								var/I = data
								var/count = 1
								while(I["[count]"] != null)
									count++
								if ((count == 1 && I["1"] == null))
									count = null
								data = count
							else
								data = length(data)
							src.var_list["[t1[2]]"] = num2text(data)
							L["[get_data(copytext(t1[2], temp + 1, length(t1[2]) + 1))]"] = data
							src.var_list["[copytext(t1[2], 1, temp)]"] = L
					counter++
				if("copytext")
					if(t1.len < 4)
						src.master.show_message("Not enough arguments for copytext.")
					else
						var
							variable = t1[2]
							string = get_data(t1[3])
							start = text2num(get_data(t1[4]))
							end = 0
						if(t1.len >= 5)
							end = text2num(get_data(t1[5]))
						if(start <= 0) start = 1
						if(end < length(string))
							src.var_list["[variable]"] = copytext(string,start,end+1)
						else
							src.var_list["[variable]"] = copytext(string,start)
					counter++
				if("replacetext")
					if(t1.len < 5)
						src.master.show_message("Not enough parameters for replacetext")
					else
						var
							variable = t1[2]
							string = get_data(t1[3])
							find = get_data(t1[4])
							replace = get_data(t1[5])
						if(length(string) >= 5000) string = copytext(string,1,5001)
						if(length(find) >= 5000) find = copytext(find,1,5001)
						if(length(replace) >= 5000) replace = copytext(replace,1,5001)
						src.var_list["[variable]"] = replacetext(string,find,replace)
					counter++
				if("findtext")
					if(t1.len < 4)
						src.master.show_message("Not enough parameters for findtext")
					else
						var
							variable = t1[2]
							string = get_data(t1[3])
							find = get_data(t1[4])
							start = 1
							end = length(string)
						if(t1.len >= 5)
							start = text2num(get_data(t1[5]))
						if(t1.len >= 6)
							end = text2num(get_data(t1[6]))
						if(start <= 0) start = 1
						if(end > length(string)) end = length(string)
						if(start)
							if(end)
								src.var_list["[variable]"] = findtext(string,find,start,end)
							else
								src.var_list["[variable]"] = findtext(string,find,start)
						else
							src.var_list["[variable]"] = findtext(string,find)
					counter++
				if("list_moveup","moveup_list")
					var/L = src.var_list["[t1[2]]"]
					if (!( istype(L, /list) ))
						counter++
					var/count = 1
					while(L["[count]"] != null)
						count++
					if (count == 1)
						L["1"] = null
						counter++
					var/x = null
					while(x < count)
						L["[x]"] = L["[x + 1]"]
						x++
					L["[count]"] = null
					src.var_list["[t1[2]]"] = L
					counter++
				if("init_list","list_init")
					src.var_list["[t1[2]]"] = list(  )
					counter++
				if("char")
					var/temp = findtext(t1[2], ":", 1, null)
					var/t = src.get_data(t1[3])
					t = text2num(t)
					if ((!( isnum(t) ) || (t > 255 || t < 1)))
						counter++
					t = ascii2text(t)
					if (!( temp ))
						if (istype(src.var_list["[t1[2]]"], /list))
							del(src.var_list["[t1[2]]"])
						src.var_list["[t1[2]]"] = t
					else
						if (istype(src.var_list["[copytext(t1[2], 1, temp)]"], /list))
							var/L = src.var_list["[copytext(t1[2], 1, temp)]"]
							L["[get_data(copytext(t1[2], temp + 1, length(t1[2]) + 1))]"] = t
							src.var_list["[copytext(t1[2], 1, temp)]"] = L
					counter++
				if("ascii")
					var/temp = findtext(t1[2], ":", 1, null)
					var/t = src.get_data(t1[3])
					if (!t)
						counter++
					t = text2ascii(t)
					if (!( temp ))
						if (istype(src.var_list["[t1[2]]"], /list))
							del(src.var_list["[t1[2]]"])
						src.var_list["[t1[2]]"] = t
					else
						if (istype(src.var_list["[copytext(t1[2], 1, temp)]"], /list))
							var/L = src.var_list["[copytext(t1[2], 1, temp)]"]
							L["[get_data(copytext(t1[2], temp + 1, length(t1[2]) + 1))]"] = t
							src.var_list["[copytext(t1[2], 1, temp)]"] = L
					counter++
				if("set")
					var/temp = findtext(t1[2], ":", 1, null)
					if (!( temp ))
						if (istype(src.var_list["[t1[2]]"], /list))
							del(src.var_list["[t1[2]]"])
						src.var_list["[t1[2]]"] = src.get_data(t1[3])
					else
						if (istype(src.var_list["[copytext(t1[2], 1, temp)]"], /list))
							var/L = src.var_list["[copytext(t1[2], 1, temp)]"]
							L["[get_data(copytext(t1[2], temp + 1, length(t1[2]) + 1))]"] = get_data(t1[3])
							src.var_list["[copytext(t1[2], 1, temp)]"] = L
					counter++
				if("getfile")
					if (src.master)
						var/F = src.master.parse2file(get_data(t1[3]))
						if (istype(src.var_list["[t1[2]]"], /list))
							del(src.var_list["[t1[2]]"])
						src.var_list["[t1[2]]"] = F
					counter++
				if("dumppath")
					if (src.master)
						var/F = get_data(t1[2])
						if ((F && istype(F, /datum/file)))
							if (istype(src.var_list["[t1[3]]"], /list))
								del(src.var_list["[t1[3]]"])
							src.var_list["[t1[3]]"] = src.master.get_path(F)
					counter++
				if("dumpfile")
					if (src.master)
						var/datum/file/normal/F = src.master.parse2file(get_data(t1[2]))
						if ((istype(F, /datum/file/normal) && !( F.flags & 1 )))
							if (istype(src.var_list["[t1[3]]"], /list))
								del(src.var_list["[t1[3]]"])
							src.var_list["[t1[3]]"] = "[F.text]"
					counter++
				if("round")
					var
						number_one = get_data(t1[2])
					src.var_list["[t1[3]]"] = round(text2num(number_one),1)
					counter++
				if("floor")
					var
						number_one = get_data(t1[2])
					src.var_list["[t1[3]]"] = round(text2num(number_one))
					counter++
				if("frac")
					var
						number_one = get_data(t1[2])
					if(findtext(number_one,"."))
						var/dec_pos = findtext(number_one,".")
						src.var_list["[t1[3]]"] = copytext(number_one,dec_pos)
					else
						src.var_list["[t1[3]]"] = "0"
					counter++
				if("eval")
					var/v1 = src.var_list["[t1[2]]"]
					var/v2
					if(t1.len >= 4)
						v2 = get_data(t1[4])
					var/n = text2num(get_data(t1[2]))
					var/n2 = 0
					if(t1.len >= 4)
						n2 = text2num(get_data(t1[4]))
					switch(t1[3])
						if("+=")
							if (istype(v1, /datum/file))
								var/datum/file/normal/F = v1
								if (istype(F, /datum/file/normal))
									F.add(v2)
							else
								if (("[text2num(v1)]" == "[v1]" && "[text2num(v2)]" == "[v2]"))
									src.var_list["[t1[2]]"] = "[text2num(v1) + text2num(v2)]"
								else
									if (istype(src.var_list["[t1[2]]"], /list))
										var/L = src.var_list["[t1[2]]"]
										var/count = 1
										while(L["[count]"] != null)
											count++
										if ((count == 1 && L["1"] == null))
											count = 1
										else
											count++
										L["[count]"] = t1[4]
										src.var_list["[t1[2]]"] = L
									else
										src.var_list["[t1[2]]"] += "[get_data(t1[4])]"
						if("-=")
							if (("[text2num(v1)]" == "[v1]" && "[text2num(v2)]" == "[v2]"))
								src.var_list["[t1[2]]"] = "[text2num(src.var_list["[t1[2]]"]) - text2num(get_data(t1[4]))]"
							else
								if (istype(src.var_list["[t1[2]]"], /list))
									var/L = src.var_list["[t1[2]]"]
									for(var/x in L)
										if (L[x] == t1[4])
											L[x] = null

									src.var_list["[t1[2]]"] = L
						if("*=")
							if (("[text2num(v1)]" == "[v1]" && "[text2num(v2)]" == "[v2]"))
								src.var_list["[t1[2]]"] = "[text2num(src.var_list["[t1[2]]"]) * text2num(get_data(t1[4]))]"
						if("/=")
							if (("[text2num(v1)]" == "[v1]" && "[text2num(v2)]" == "[v2]"))
								src.var_list["[t1[2]]"] = "[text2num(src.var_list["[t1[2]]"]) / text2num(get_data(t1[4]))]"
						if("++")
							n++
							src.var_list["[t1[2]]"] = "[n]"
						if("--")
							n--
							src.var_list["[t1[2]]"] = "[n]"
						if("<<")
							n = n << n2
							src.var_list["[t1[2]]"] = "[n]"
						if(">>")
							n = n >> n2
							src.var_list["[t1[2]]"] = "[n]"
						if("%")
							n = n % n2
							src.var_list["[t1[2]]"] = "[n]"
						if("^")
							n = n ^ n2
							src.var_list["[t1[2]]"] = "[n]"
						if("|")
							n = n | n2
							src.var_list["[t1[2]]"] = "[n]"
						if("&")
							n = n & n2
							src.var_list["[t1[2]]"] = "[n]"

						else
							if (src.master)
								src.master.show_message("Unknown operand for eval: [t1[3]]")
					counter++
				if("shell")
					if (src.master)
						var/dta = get_data(t1[2])
						src.master.parse_string(dta, src)
					counter++
				if("end")
					if ((t1.len >= 2 && (t1[2] && src.master)))
						src.master.err_level = t1[2]
					del(src)
					return
				if("if")
					if (t1.len >= 5)
						var/go_on = null

						switch(t1[3])
							if(">=")
								if (text2num(src.get_data(t1[2])) >= text2num(get_data(t1[4])))
									go_on = 1
							if("<=")
								if (text2num(src.get_data(t1[2])) <= text2num(get_data(t1[4])))
									go_on = 1
							if(">")
								if (text2num(src.get_data(t1[2])) > text2num(get_data(t1[4])))
									go_on = 1
							if("<")
								if (text2num(src.get_data(t1[2])) < text2num(get_data(t1[4])))
									go_on = 1
							if("==")
								var/datum/file/v1 = src.get_data(t1[2])
								var/datum/file/v2 = get_data(t1[4])
								if ((istype(v1, /datum/file) && istype(v2, /datum/file)))
									if (v1.compare(v2))
										go_on = 1
								else
									if(isnum(v1)) v2 = text2num(v2)
									if ((v1) == (v2))
										go_on = 1
							if("!=","<>")
								var/datum/file/v1 = src.get_data(t1[2])
								var/datum/file/v2 = get_data(t1[4])
								if ((istype(v1, /datum/file) && istype(v2, /datum/file)))
									if (!( v1.compare(v2) ))
										go_on = 1
								else
									if (v1 != v2)
										go_on = 1
						if (go_on)
							if (text2num(goto_array["[t1[5]]"]) > 0)
								counter = text2num(goto_array["[t1[5]]"])


						else
							counter++
					else
						counter++
				else
					if(t1[1])
						if (src.master)
							src.master.show_message("Invalid command: [t1[1]] ([t1.len])")
					counter++