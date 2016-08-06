open Arg ;;
open Tcsargs;;
open Tcsbasedata;;
open Basics ;;
open Paritygame ;;
open Tcsstrings ;;
open Str ;;
open Stratimpralgs;;
open Tcsset;;

let out s =
	print_string s;
	flush stdout

let _ =
	let header = Info.get_title "Parity Game Improvement Arena Tool" in
	  
	SimpleArgs.parsedef [] (fun _ -> ()) (header ^ "Usage: imprarena\n" ^
                                           "Provides some information about a parity game improvement arena.");

	let (in_channel,name) = (stdin,"STDIN") in

	let game = Parsers.parse_parity_game in_channel in
	
	let pre_strategy = Array.make (pg_size game) "" in
	
	let rg = Str.regexp "\\(.*\\)\\[\\(.*\\)\\]" in
	
	for i = 0 to pg_size game - 1 do
		if pg_get_owner game i = plr_Even then (
			let desc = OptionUtils.get_some (pg_get_desc game i) in
			if not (Str.string_match rg desc 0) then failwith "No strategy included!";
			pre_strategy.(i) <- Str.matched_group 2 desc;
			pg_set_desc game i (Some (Str.matched_group 1 desc))
		);
	done;
	
	let strategy = Array.init (pg_size game) (fun i ->
		if pre_strategy.(i) = "" then -1
		else pg_find_desc game (Some pre_strategy.(i))
	) in
	
	let valu = evaluate_strategy game node_total_ordering_by_position strategy in
	
	let compare_by_desc i j =
		compare (pg_get_desc game i) (pg_get_desc game j)
	in
	
	let ordered = ref (TreeSet.empty compare_by_desc) in
	let longest = ref 0 in
	
	for i = 0 to pg_size game - 1 do
		longest := max !longest (String.length (OptionUtils.get_some (pg_get_desc game i)));
		ordered := TreeSet.add i !ordered
	done;
	
	let getd i = (StringUtils.fillup (OptionUtils.get_some (pg_get_desc game i)) !longest ' ') in
	
	TreeSet.iter (fun i ->
		out (getd i);
		out " | ";
		let pl = pg_get_owner game i in
		let tr = pg_get_successors game i in 
		let j =
			if pl = plr_Even then strategy.(i)
			else best_decision_by_valuation_ordering game node_total_ordering_by_position valu i
		in
		out (getd j);
		out " | ";
		if pl = plr_Even then (
			ns_iter (fun j ->
				if node_valuation_ordering game node_total_ordering_by_position valu.(strategy.(i)) valu.(j) < 0
				then out (getd j ^ " ");
			) tr;
		);
		out "\n";
	) !ordered;

	out "\n";;
