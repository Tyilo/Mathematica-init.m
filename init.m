(* ::Package:: *)
(* Timestamp: 2015-12-09 15:11 *)

(** User Mathematica initialization file **)

$minVersion = 10;

If[$VersionNumber < $minVersion,
	MessageDialog["You need at least Mathematica v" <> ToString @ $minVersion <>
		" to use this init.m file.\nYou're using Mathematica v" <> First @ StringSplit[$Version, " "] <> "."]
];


(* Needed to make function appear in the auto-complete prompt *)
Begin["System`"];

(* Disable WolframAlpha *)
Unprotect[WolframAlpha];
ClearAll[WolframAlpha];
WolframAlpha[x__] := Null;
Protect[WolframAlpha];

(* My definitions *)

(* Hangs Mathematica 10.1
Module[{t},
	t = CreateScheduledTask[
		"initFileScheduledTask";
		If[URLFetch@"http://example.org/" =!= Null,
			t = Select[ScheduledTasks[],
				StringMatchQ[ToString@#[[2]], StartOfString ~~ "initFileScheduledTask" ~~ ___] &
			];
			RemoveScheduledTask @ t;
			updateInitFile[FromInitFile -> True];
		],
		1
	];
	StartScheduledTask @ t;
];
*)


updateInitFile::networkError = "Failed to retrieve the latest init.m version from github.";
Options[updateInitFile] := {DryRun -> False, FromInitFile -> False};
updateInitFile[options:OptionsPattern[]] := Module[{initPath, current, f, newest, m},
	initPath = ToFileName[{$UserBaseDirectory, "Kernel"}, "init.m"];
	f = OpenRead@initPath;
	current = StringJoin@ReadList[f, Character];
	Close@f;
	newest = URLFetch@"https://raw.github.com/Tyilo/Mathematica-init.m/master/init.m";

	If[newest == $Failed || StringSplit[newest, "\n"][[1]] != "(* ::Package:: *)",
		Message[updateInitFile::networkError];
		Return[];
	];

	(* URLFetch truncates the last newline *)
	newest = newest <> "\n";

	getTimestamp[str_] := Module[{m},
		m = StringCases[str, StartOfLine ~~ "(* Timestamp: " ~~ Shortest@x__ ~~ " *)" ~~ EndOfLine :> x];
		DateList@m[[1]]
	];

	If[QuantityMagnitude@DateDifference[getTimestamp@current, getTimestamp@newest] <= 0,
		Return["Your init.m is already at the latest version."];
	];


	If[OptionValue[DryRun] == False,
		WriteString[f = OpenWrite@initPath, newest];
		Close@f,
		Print@"Dry run, init.m not changed."
	];

	m = "Mathematica's init.m has been updated!\nRestart Mathematica to apply the changes.";
	If[OptionValue[FromInitFile]
		MessageDialog @ m;,
		m
	]
];

Module[{path, systemPath, userPath},
	path = FileNameJoin@{"SystemFiles", "FrontEnd", "TextResources", $OperatingSystem /. "MacOSX"->"Macintosh", "KeyEventTranslations.tr"};
	systemPath = FileNameJoin@{$InstallationDirectory, path};
	userPath = FileNameJoin@{$UserBaseDirectory, path};
	If[FileExistsQ@systemPath,
		If[FileExistsQ@userPath,
			Null
		];
	];
];


reloadInitFile[] := Import@ToFileName[{$UserBaseDirectory, "Kernel"}, "init.m"];

fixMathematica[] := Module[{},
	DeleteDirectory[FileNameJoin[{$UserBaseDirectory, "FrontEnd"}], DeleteContents -> True];
	Print["Please restart Mathematica"];
];

preloadPaclets[] := (
	ChemicalData[All,Preload];
	ElementData[All,Preload];
	AstronomicalData[All,Preload];
	ParticleData[All,Preload];
	RebuildPacletData[];
);

SinDeg[d_] := Sin[d * Degree];
CosDeg[d_] := Cos[d * Degree];
TanDeg[d_] := Tan[d * Degree];

ArcSinDeg[d_] := ArcSin[d] / Degree;
ArcCosDeg[d_] := ArcCos[d] / Degree;
ArcTanDeg[d_] := ArcTan[d] / Degree;

CenterDot = Times;

PlusMinus[{a1_, a2_}] := Module[{r},
	r = {a1, -a2};
	If[r[[1]] == r[[2]], r[[1]], r, r]
];
PlusMinus[a_] := PlusMinus[{a, a}];
PlusMinus[{a1_, a2_}, {b1_, b2_}] := Module[{r},
	r = {a1 + b1, a2 - b2};
	If[r[[1]] == r[[2]], r[[1]], r, r]
];
PlusMinus[{a1_, a2_}, b_] := PlusMinus[{a1, a2}, {b, b}];
PlusMinus[a_, {b1_, b2_}] := PlusMinus[{a, a}, {b1, b2}];
PlusMinus[a_, b_] := PlusMinus[{a, a}, {b, b}];

MinusPlus[{a1_, a2_}] := Module[{r},
	r = {-a1, a2};
	If[r[[1]] == r[[2]], r[[1]], r, r]
];
MinusPlus[a_] := MinusPlus[{a, a}];
MinusPlus[{a1_, a2_}, {b1_, b2_}] := Module[{r},
	r = {a1 - b1, a2 + b2};
	If[r[[1]] == r[[2]], r[[1]], r, r]
];
MinusPlus[{a1_, a2_}, b_] := MinusPlus[{a1, a2}, {b, b}];
MinusPlus[a_, {b1_, b2_}] := MinusPlus[{a, a}, {b1, b2}];
MinusPlus[a_, b_] := MinusPlus[{a, a}, {b, b}];


InfixNotation[ParsedBoxWrapper["\[CirclePlus]"], BitXor];

openNotationPalette[] := (
	Notation`AutoLoadNotationPalette = True;
	Unprotect @ Notation`Private`protected;
	<< Notation`;
);

allProperties[f_, elem_] := Grid[{#, f[elem, #]} & /@ f["Properties"], Background -> {None, {{White, Lighter[Gray, 2/3]}}}];
propertyWithUnits[f_, args__] := Quantity[f[args], f[args, "Units"]];

intInterval::multipleSymbols = "Found multiples symbols in expression: `1`. Using the symbol `2`.";
intInterval[expr_, {x_, xmin_, xmax_}] := (expr /. x -> xmax) - (expr /. x -> xmin)
intInterval[expr_, {xmin_, xmax_}] := Block[{symbols, symbol},
	symbols = DeleteDuplicates @ Select[Cases[expr, _Symbol, Infinity], N[#] === # &];
	If[Length @ symbols > 1,
		Message[intInterval::multipleSymbols, symbols, First @ symbols];
	];
	symbol = If[Length @ symbols == 0, Null, First @ symbols];
	intInterval[expr, {symbol, xmin, xmax}]
];

plotIntersect[f1_, f2_, o_, options_] := Block[{x, solution},
	x = o[[1]];
	solution = Solve[y == f1 && y == f2, {x, y}];
	Show[Plot[{f1, f2}, o], ListPlot[Transpose[{x /. solution, y /. solution}], PlotStyle -> {Red, PointSize[0.0125]}], options]
];

plotIntersect[f1_, f2_, o_] := plotIntersect[f1, f2, o, {}];

plotDefiniteIntegral[expr_, {x_, xmin_, xmax_}, margin_] := Show@{
	Plot[expr, {x, xmin - margin, xmax + margin}, AxesOrigin -> {0, 0}, Epilog -> {
		{Black, Line[{{xmin, 0}, {xmin, expr /. x -> xmin}}]},
		{Black, Line[{{xmax, 0}, {xmax, expr /. x -> xmax}}]}
	}],
	Plot[expr, {x, xmin, xmax}, Filling -> 0, FillingStyle -> {LightRed, LightGreen}]
};

plotDefiniteIntegral[expr_, {x_, xmin_, xmax_}] := plotDefiniteIntegral[expr, {x, xmin, xmax}, (xmax - xmin) / 6];

fitPlotOptionNames = {showFunction, showParams, showRSquared, printLabels};
Options[fitPlot] = Table[x -> True, {x, fitPlotOptionNames}] ~Join~ Options[Plot] ~Join~ Options[NonlinearModelFit];

fitPlot[data_, expr_, pars_, vars_, options:OptionsPattern[]] := Block[{nonlinearModelFitOptionNames, plotOptionNames, nonlinearModelFitOptions, plotOptions, fit, params, col1, plotRange, xmin, xmax, labelOptions, labels, R, otherOptions, fitted},
	Assert[Length@Dimensions[data] >= 2 && Dimensions[data][[2]] == 2];
	Assert[Head@vars == Symbol];

	nonlinearModelFitOptionNames = First /@ Options[NonlinearModelFit];
	plotOptionNames = Complement[First /@ Options[Plot], nonlinearModelFitOptionNames];

	{nonlinearModelFitOptions, plotOptions} = Table[Cases[{options}, HoldPattern @ Evaluate[Alternatives @@ l -> _]], {l, {nonlinearModelFitOptionNames, plotOptionNames}}];

	fit = NonlinearModelFit[data, expr, pars, vars, Evaluate[Sequence @@ nonlinearModelFitOptions]];
	params = fit["BestFitParameters"];
	col1 = data[[All,1]];
	plotRange = OptionValue[PlotRange];
	{xmin, xmax} = If[Head@plotRange == List && Length@plotRange == 2 && Length@plotRange[[1]] == 2,
		plotRange[[1]],
		{Automatic, Automatic}
	];
	xmin = xmin /. Automatic -> Min[col1];
	xmax = xmax /. Automatic -> Max[col1];
	labelOptions = Complement[fitPlotOptionNames, {printLabels}];
	labels = Flatten@Position[OptionValue[#] & /@ labelOptions, True] /. {
		1 -> Normal[fit],
		2 -> params,
		3 -> R^2 == fit["RSquared"]
	};
	If[OptionValue[printLabels],
		Print[Column @ labels]
	];
	Plot[fit[vars], {vars, xmin, xmax},
		PlotLabel -> Column@labels,
		Epilog -> {PointSize[Medium], Point[data]},
		Evaluate[Sequence @@ plotOptions]
	]
];

fitPlot[data_, expr_, pars_, vars_] := fitPlot[data, expr, pars, vars, Sequence@{}];

plotWithPoints[expr_, {x_, xmin_, xmax_}, xs_, options:OptionsPattern[Plot]] := Plot[expr, {x, xmin, xmax},
	Epilog -> {Black, PointSize[Medium], Table[Tooltip[Point[{n, expr /. x -> n}], {n, expr /. x -> n}], {n, xs}]},
	options
];


plot3DCrossSection[eq_, param1_, param2_] := Module[{a, b},
	Manipulate[
		GraphicsRow[{
			Plot3D[eq, Evaluate@param1, Evaluate@param2, Mesh -> {{a}, {b}}],
			Plot[eq /. param2[[1]] -> b, Evaluate@param1, AxesLabel -> {"x", "z"}],
			Plot[eq /. param1[[1]] -> a, Evaluate@param2, AxesLabel -> {"y", "z"}]
		}, ImageSize -> Full],
	{{a, Mean[param1[[2 ;; 3]]], "x"}, param1[[2]], param1[[3]]},
	{{b, Mean[param2[[2 ;; 3]]], "y"}, param2[[2]], param2[[3]]}]
];

plotVectors[v_?MatrixQ, o_List, opt:OptionsPattern[Show]] := Module[{n = Dimensions[v][[2]], graphics},
	graphics = If[n==2, Graphics, If[n==3, Graphics3D, Null]];
	Assert[graphics != Null];
	Show[graphics[Append[o, Arrow[{Array[0&, n], Flatten@#}]]& /@ v, Method -> {"AxesInFront" -> False}], opt]
];
plotVectors[v_?MatrixQ, opt:OptionsPattern[Show]] := plotVectors[v, {}, opt];
plotVectors[v_?VectorQ, o_List, opt:OptionsPattern[Show]] := plotVectors[{v}, o, opt];
plotVectors[v_?VectorQ, opt:OptionsPattern[Show]] := plotVectors[v, {}, opt];

unitArrows[m_?MatrixQ, o_List, opt:OptionsPattern[Show]] := Module[{n=Length@m, graphics},
	graphics = If[n==2, Graphics, If[n==3, Graphics3D, Null]];
	Assert[graphics != Null];
	plotVectors[Table[m . UnitVector[n, i], {i, 1, n}], {Thick, Darker@Green} ~ Join ~ o, opt]
];
unitArrows[m_?MatrixQ, opt:OptionsPattern[Show]] := unitArrows[m, {}, opt];
unitArrows[n_?NumberQ, o_List, opt:OptionsPattern[Show]] := unitArrows[IdentityMatrix[n], o, opt];
unitArrows[n_?NumberQ, opt:OptionsPattern[Show]] := unitArrows[n, {}, opt];

lineElementPlot[f_, x_, y_, options:OptionsPattern[VectorPlot]] := VectorPlot[
	Normalize@{1, f}, x, y, options,
	VectorStyle -> Arrowheads[0],
	VectorScale -> 0.04
];

removeSubscript[s_String] := StringReplace[s,
	"\!\(\*SubscriptBox[\(" ~~ Shortest[x__] ~~ "\), \(" ~~ Shortest[y__] ~~ "\)]\)" :> x <> y
];
removeSubscript[x_] := x;

molecularWeight[s_String] :=
	ToExpression @ StringReplace[
		StringReplace[
			StringReplace[removeSubscript @ s,
				x:RegularExpression["[A-Z][a-z]*"] :>
				"ElementData[\"" <> x <> "\",\"AtomicWeight\"]+"
			],
			x:DigitCharacter .. :> "*" <> x <> "+"],
		{"+*" -> "*", "+" ~~ EndOfString -> "", "+)" -> ")"}
	];

chemicalTable[formula_] := Module[{chemicals, properties},
	chemicals = Check[ChemicalData[removeSubscript @ formula, "StandardName"], Break[]];
	chemicals = If[Length[chemicals] == 0, {chemicals}, chemicals];
	properties = {"StandardName", "MolecularFormulaDisplay", "StructureDiagram"};
	OpenerView[{formula,
		Grid[
			Table[
				(Table[
					ChemicalData[#, property],
					{property, properties}
				] &)[chemical],
				{chemical, chemicals}
			],
		Frame -> All]
	}, True]
];

$thermodynamicData = {{"Ag(s)", 0, 42.55, 0}, {"Ag+(aq)", 105.79, 73.45, 77.16},
 {"AgCl(s)", -127.01, 96.25, -109.86}, {"AgI(s)", -61.87, 115.83, -66.22},
 {"Ba(OH)2\[CenterDot]H2O(s)", -3342.2, 427, -2792.2}, {"BaCl2\[CenterDot]2H2O(s)", -1456.9, 202.,
  -1293.2}, {"C(s,grafit)", 0, 5.74, 0}, {"C(s,diamant)", 1.895, 2.377, 2.832},
 {"CH4(g)", -74.6, 186.3, -50.5}, {"C2H4(g)", 52.3, 219.3, 68.27},
 {"C7H16(l)", -224.2, 326.1, 1.89}, {"CH3OH(l)", -239.2, 126.8, -166.6},
 {"CH3CH2OH(l)", -277.6, 160.7, -174.8}, {"CO(g)", -110.53, 197.66, -137.25},
 {"CO2(g)", -393.51, 213.785, -394.4}, {"CaCO3(s)", -1206.92, 92.9, -1128.84},
 {"CaO(s)", -634.92, 38.1, -603.3}, {"Cl-(aq)", -167.08, 56.6, -131.2},
 {"CrO4--(aq)", -881.15, 50.2, -727.8}, {"H2(g)", 0, 130.68, 0},
 {"H+(aq)", 0, 0, 0}, {"H3O+(aq)", -285.83, 69.95, -237.13},
 {"H2O(l)", -285.83, 69.95, -237.13}, {"H2O(g)", -241.8, 188.8, -228.6},
 {"HCl(g)", -92.3, 186.9, -95.3}, {"HI(g)", 25.94, 206.44, 1.32},
 {"I2(s)", 0, 116.14, 0}, {"I-(aq)", -56.78, 106.45, -51.6},
 {"N2(g)", 0, 191.61, 0}, {"NH3(g)", -45.5, 192.8, -16.4},
 {"NH4-(aq)", -132.4, 113.4, -79.3}, {"NH4Cl(s)", -314.6, 94.6, -202.9},
 {"NH4NO3(s)", -365.3, 151.1, -183.9}, {"NO(g)", 91.2, 210.8, 87.6}, {"NO2(g)", 33.1, 240.1, 51.3},
 {"N2O4(g)", 11.4, 304.3, 99.8}, {"NO3-(aq)", -207, 146.4, -111.3},
 {"Na(s)", 0, 51.3, 0}, {"Na+(aq)", -240.34, 58.45, -261.9},
 {"NaCl(s)", -411.2, 72.1, -384.1}, {"O2(g)", 0, 205.15, 0},
 {"OH-(aq)", -230.01, -10.9, -157.2}, {"SO2(g)", -296.81, 248.23, -300.1},
 {"SO3(g)", -395.72, 256.83, -371.03}};

deltaThermo[reactants_ -> products_, i_Integer, rule_List] :=
	Quantity[(removeSubscript //@ products /. rule) - (removeSubscript //@ reactants /. rule),
		Evaluate@If[i == 2, "Joules"/("Moles"*"Kelvins"), "Kilojoules"/"Moles"]];
deltaThermo[r_Rule, i_Integer] := deltaThermo[r, i, Rule @@@ $thermodynamicData[[All, {1, i + 1}]]];
deltaH[r_Rule] := deltaThermo[r, 1];
deltaS[r_Rule] := deltaThermo[r, 2];
deltaG[r_Rule] := deltaThermo[r, 3];
deltaH[r_Rule, otherRule_] := deltaThermo[r, 1, otherRule];
deltaS[r_Rule, otherRule_] := deltaThermo[r, 2, otherRule];
deltaG[r_Rule, otherRule_] := deltaThermo[r, 3, otherRule];

(* Deca is intentionally left out as only one character prefixes are supported *)
$mySIPrefixes={"Y"->"Yotta","Z"->"Zetta","E"->"Exa","P"->"Peta","T"->"Tera","G"->"Giga","M"->"Mega","k"->"Kilo","h"->"Hecto","d"->"Deci","c"->"Centi","m"->"Milli","\[Mu]"|"\[Micro]"->"Micro","n"->"Nano","p"->"Pico","f"->"Femto","a"->"Atto","z"->"Zepto","y"->"Yocto"};
$unitAbbreviations={"\[Degree]"->"angularDegrees","\[Degree]C"|"℃"->"degreesCelsius","\[Degree]F"|"℉"->"degreesFahrenheit","\[CapitalOmega]"->"ohms","A"->"amperes","Bq"->"becquerels","C"->"coulombs","Da"|"u"->"daltons","F"->"farads","Gy"->"grays","H"->"henries","Hz"->"hertz","J"->"joules","K"->"kelvins","L"->"liters","ly"->"lightYears","M"->"molar","N"->"newtons","Pa"->"pascals","pc"->"parsecs","S"->"siemens","Sv"->"sieverts","T"->"teslas","V"->"volts","W"->"watts","Wb"->"webers","a"->"julianYears","atm"->"atmospheres","au"->"astronomicalUnit","bar"->"bars","cd"->"candelas","d"->"days","eV"->"electronvolts","g"->"grams","h"->"hours","kat"->"katals","lm"->"lumens","lx"->"lux","m"->"meters","min"->"minutes","mol"->"moles","rad"->"radians","s"->"seconds","sr"->"steradians"};
$constantAbbreviations={"\[CurlyEpsilon]0"|"\[Epsilon]0"->"electricConstant","\[Mu]0"->"magneticConstant","\[Sigma]"->"stefanBoltzmannConstant","b"->"WienWavelengthDisplacementLawConstant","c"->"speedOfLight","e"->"elementaryCharge","G"->"gravitationalConstant","h"->"planckConstant","k"->"boltzmannConstant","me"->"electronMass","NA"->"avogadroConstant","R"->"molarGasConstant"};

firstDropWhile[list_, cond_] := Module[{l},
	l = LengthWhile[list, cond];
	If[l == Length[list],
		Null,
		list[[l+1]]
	]
];
stringCapitalize[str_String] := ToUpperCase @ Characters[str][[1]] <> StringDrop[str, 1];
replaceSIPrefix[str_String] := (Characters[str][[1]] /. $mySIPrefixes) <> StringDrop[str, 1];

fullName[str_String, rule_] := Module[{applyRule, transformations, candidates},
	applyRule = (# /. rule)&;
	transformations = {Identity, stringCapitalize,
		Composition[stringCapitalize, applyRule], replaceSIPrefix,
		(replaceSIPrefix@Characters[#][[1]]) <> applyRule[StringDrop[#,1]]&
	};
	candidates = Flatten[{#, # <> "s"}& /@ Through[transformations[str]]];
	firstDropWhile[candidates, !KnownUnitQ@# &]
];

unitFullName[str_String] := fullName[str, $unitAbbreviations];
knownUnitAbbreviationQ[str_String] := unitFullName[str] =!= Null;

constantFullName[str_String] := fullName[str, $constantAbbreviations];
knownConstantAbbreviationQ[str_String] := constantFullName[str] =!= Null;

fullUnit[u_] := Module[{},
	Evaluate[u /. {s_String?LetterQ :> fullName[s, $unitAbbreviations ~ Join ~ $constantAbbreviations], CenterDot -> Times}]
];

quantity[u_] := Quantity[fullUnit@u];
quantity[m_, u_] := Quantity[m, fullUnit@u];
unitConvert[q_] := UnitConvert[q];
unitConvert[q_, u_] := UnitConvert[q, fullUnit@u];

If[$FrontEnd =!= Null,
	CurrentValue[$FrontEnd, InputAliases] = DeleteCases[CurrentValue[$FrontEnd, InputAliases], "qu"|"const"|"dintintt" -> _];

	CurrentValue[$FrontEnd, InputAliases] = Join[CurrentValue[$FrontEnd, InputAliases], {
		"qu" -> TemplateBox[{"\[SelectionPlaceholder]", "\[Placeholder]"},
			"QuantityUnit", Tooltip -> "Unit Template",
			DisplayFunction -> (PanelBox[RowBox[{#1, StyleBox[#2, "QuantityUnitTraditionalLabel"]}], FrameMargins -> 2] &),
			InterpretationFunction -> (With[{unit = #2 /. SubscriptBox[a_, b_] :> ToString[a] ~~ ToString[b] /. s_String?knownUnitAbbreviationQ :> "\""~~(unitFullName[s])~~"\"" /. s_String :> (s /. "\[CenterDot]" -> "*")},
				(*Print[unit];*)
				If[KnownUnitQ@@MakeExpression@unit,
					RowBox[{"Quantity", "[", #1, ",", unit, "]"}],
					RowBox[{"Quantity", "[", #1, ",", "\""~~StringTake[ToString[MakeExpression@#2, InputForm], {14, -2}]~~"\"", "]"}]
				]
			] &)
		],
		"const" -> TemplateBox[{"\[SelectionPlaceholder]"},
			"Constant", Tooltip -> "Constant Template",
			DisplayFunction -> (PanelBox[RowBox[{StyleBox[#, "QuantityUnitTraditionalLabel"]}], FrameMargins -> 2] &),
			InterpretationFunction -> (With[{const = # /. SubscriptBox[a_, b_] :> ToString[a] ~~ ToString[b] /. s_String?knownConstantAbbreviationQ :> "\""~~(constantFullName[s])~~"\""},
				(*Print[const];*)
				If[KnownUnitQ@@MakeExpression@const,
					RowBox[{"Quantity", "[", 1, ",", const, "]"}],
					RowBox[{"Quantity", "[", 1, ",", "\""~~StringTake[ToString[MakeExpression@#, InputForm], {14, -2}]~~"\"", "]"}]
				]
			] &)
		],
		"vect" -> TemplateBox[{GridBox[{{"\[SelectionPlaceholder]"}, {"\[Placeholder]"}}]},
			"Vector",
			DisplayFunction -> (RowBox[{
				StyleBox["(", SpanMaxSize -> Infinity], #1, StyleBox[")", SpanMaxSize -> Infinity]
			}] &),
			InterpretationFunction -> (RowBox[{"Flatten", "[", #, "]"}]&)
		],
		"binom" -> TemplateBox[{GridBox[{{"\[SelectionPlaceholder]"}, {"\[Placeholder]"}}]},
			"Binomial",
			DisplayFunction -> (RowBox[{
				StyleBox["(", SpanMaxSize -> Infinity], #1, StyleBox[")", SpanMaxSize -> Infinity]
			}] &),
			InterpretationFunction -> (RowBox[{"Binomial", "@@", "Flatten", "[", #1, "]"}]&)
		],
		"mat" -> TemplateBox[{GridBox[{{"\[SelectionPlaceholder]", "\[Placeholder]"}, {"\[Placeholder]", "\[Placeholder]"}}]},
			"Matrix",
			DisplayFunction -> (RowBox[{
				StyleBox["[", SpanMaxSize -> Infinity], #1, StyleBox["]", SpanMaxSize -> Infinity]
			}] &)],
		"dintintt" -> SubsuperscriptBox[RowBox[{"\[LeftBracketingBar]", "\[SelectionPlaceholder]", "\[RightBracketingBar]"}], "\[Placeholder]", "\[Placeholder]"],
		"abs" -> RowBox[{"\[LeftBracketingBar]", "\[SelectionPlaceholder]", "\[RightBracketingBar]"}],
		"norm" -> RowBox[{"\[LeftDoubleBracketingBar]", "\[SelectionPlaceholder]", "\[RightDoubleBracketingBar]"}]
	}];
];

pow00eq1[x_, y_] := If[x == 0 && y == 0, 1, x ^ y];
solvePolynomialCoordinates[coordinates_] := Module[{length, equations, variables},
	length = Length[coordinates];
	equations = {};
	variables = {};
	For[i = 1,
		i <= length,
		i++,
		variables = Append[variables, ToExpression[FromCharacterCode[96 + i]]];
		rightHand = 0;
		For[j = 1,
			j <= length,
			j++,
			rightHand += ToExpression[FromCharacterCode[96 + j]] * pow00eq1[coordinates[[i]][[1]], (length - j)];
		];
		equations = Append[equations, coordinates[[i]][[2]] == rightHand]
	];
	Solve[equations, variables][[1]]
];

polarRegionPlot[pred_, {th_, thmin_, thmax_}, {r_, rmin_, rmax_}, options:OptionsPattern[RegionPlot]] := Module[{x, y, th2}, RegionPlot[
	pred /. {r -> Sqrt[x^2 + y^2], th -> Mod[ArcTan[x, y], 2 Pi]}, {x, -rmax, rmax}, {y, -rmax, rmax},
	Frame -> False,
	Epilog -> First @ PolarPlot[rmax, {th2, 0, $MachineEpsilon},
		PolarAxes -> True,
		PolarGridLines -> {Automatic, Range[rmax]},
		PolarTicks -> {Drop[Table[i, {i, 0, 2 Pi, Pi/4}], -1], Automatic}
	],
	PlotRangePadding -> Floor@({rmax, rmax} / 3 + 1),
	options
]];

walkRowReduce[matrix_?MatrixQ] := Module[{copy, sorted, rows, cols, r, c, first, el},
	copy = matrix[[ ;; ]];
	Print[copy];
	{rows, cols} = Dimensions@copy;
	sorted = SortBy[copy, FirstPosition[x_ /; x != 0]];
	If[copy != sorted,
		copy = sorted;
		Print["Switching rows:"];
		Print[copy];
	];
	For[c = 1, c <= Min[cols - 1, rows], c++,
		el = copy[[c, c]];
		If[el == 0,
			Continue[];
		];
		If[el != 1,
			Print["Dividing row ", c, " with ", el, ":"];
			copy[[c]] /= el;
			Print[copy];
		];
		For[r = 1, r <= rows, r++,
			If[r == c,
				Continue[];
			];
			el = copy[[r, c]];
			If[el != 0,
				Print["Subtracting ", el, " times row ", c, " from row ", r, ":"];
				copy[[r]] -= el * copy[[c]];
				Print[copy];
			];
		];
	];

	RowReduce@matrix
];

criticalPoints[f_, {x_ ,y_ }] := Module[{sol, fxx, d, pts, d1, fxx1, table},
	sol = Solve[D[f, x] == 0 && D[f, y] == 0, {x, y}, Reals];
	If[Length@sol == 0,
		Return["No critical points"];
	];
	fxx = D[f, {x, 2}];
	d = fxx * D[f, {y, 2}] - D[f, x, y] ^ 2;
	pts = {x, y, f} /. sol;
	table = Table[
		{d1, fxx1} = {d, fxx} /. {x -> pts[[n,1]], y -> pts[[n,2]]};
		{pts[[n]], d1, fxx1,
			Which[d1 > 0 && fxx1 > 0, "Minimum",
			      d1 > 0 && fxx1 < 0, "Maximum",
				  d1 < 0, "Saddle",
				  d1 == 0, "Unknown"
			]
		},
		{n, Length@pts}
	];
	Grid[Prepend[table, {"Point", "D(x, y)", "\!\(\*SubscriptBox[\(f\), \(xx\)]\)(x,y)", "Type"}], Frame -> All]
];

truthTable[expr_, vars_List] := Module[{n, d, table},
	n = Length@vars;
	table = Table[
		d = PadLeft[IntegerDigits[x, 2], n];
		Append[d, Boole @ expr /. Thread[vars -> ((# != 0) & /@ d)]],
		{x, 0, 2^n - 1}
	];
	Grid[Prepend[table, Append[vars, expr]], Frame -> All]
];

maxBigO[l_, n_] := Switch[Length@l,
	1, First@l,
	2, If[Limit[Abs[First@l / Last@l], n -> Infinity] === 0, Last@l, First@l],
	_, maxBigO[{maxBigO[Take[l, 2], n], maxBigO[Drop[l, 2], n]}, n]
];
bigOSimplify[expr_, n_] := 1 /; FreeQ[expr, n];
bigOSimplify[expr_Plus, n_] := bigOSimplify[maxBigO[expr, n], n];
bigOSimplify[expr_Times, n_] := (If[FreeQ[#, n], 1, bigOSimplify[#, n]] &) /@ expr;
bigOSimplify[a_Plus ^ b_, n_] := maxBigO[a, n] ^ b;
bigOSimplify[expr_, n_] := bigOSimplify[FunctionExpand@expr, n] /; expr =!= FunctionExpand@expr;
bigOSimplify[expr_, n_] := expr;

(* Borrowed definitions *)

(* http://mathematica.stackexchange.com/a/40168/704 *)
Attributes[hold] = {HoldAll};
hold[x_] := HoldForm@x /. Cases[Hold@x, s_Symbol :> (HoldPattern@s -> s), Infinity];

manToGif[man_, name_String, step_Integer] :=
Export[name <> ".gif",
	Import[
		Export[name <> Which[$OperatingSystem == "MacOSX", ".mov", $OperatingSystem == "Windows", ".avi"],
	 man],"ImageList"][[1 ;; -1 ;; step]]
];

numPlot[ss_,{s_,e_},ee_]:=numPlot[{{ss,{s,e},ee}}];
numPlot[ints:{{_String,{_?NumericQ,_?NumericQ},_String}..}]:=Module[{i=0,c=ColorData[1,"ColorList"]},With[{min=Min[ints[[All,2,1]]],max=Max[ints[[All,2,2]]]},Graphics[Table[With[{ss=int[[1]],s=int[[2,1]],e=int[[2,2]],ee=int[[3]]},{c[[++i+1]],Thickness[.01],Text[Style[ss,Large,c[[i+1]],Bold],{s,i}],Text[Style[ee,Large,c[[i+1]],Bold],{e,i}],Line[{{s,i},{e,i}}]}],{int,ints}],Axes->{True,False},AxesStyle->Directive[Thin,Blue,12],PlotRange->{{0,max+.2 Abs@(min-max)},{0,++i}},AspectRatio->.2]]];

SetAttributes[traceViewCompact, {HoldAllComplete}];
traceViewCompact[expr_] :=
Module[{steps = {}, stack = {}, pre, post, show, default = False},
		pre[e_] := (stack = {steps, stack}; steps = {});
		post[e_,
			 r_] := (steps = First@stack~Join~{show[e, HoldForm@r, steps]};
					 stack = stack[[2]]);
		SetAttributes[post, HoldAllComplete];
		show[e_, r_, steps_] :=
		Module[{open = False},
			   Grid[steps /. {{} -> {{"Expr  ",
			Item[e, Background -> GrayLevel@.8]}}, _ -> {{"Expr  ",
				e}, {Toggler[
							 Dynamic@
							 open, {True ->
								 Button["Steps", Appearance -> {"DialogBox", "Pressed"}],
								 False -> Button@"Steps"}],
					steps /. {{} -> Style["no definitions apply", Italic], _ :>
						Dynamic@
						If[open, Column@steps,
						   Grid@{{Length@steps, "steps"}}]}}, {"Result", r}}},
					Alignment -> {Left, Center}, Frame -> All,
					Spacings -> Automatic, Background -> {{Hue[.65, .1, 1]}, None}]];
		TraceScan[pre, expr, ___, post];
		Deploy@
		Column@{Opener@Dynamic@default,
		Dynamic@Pane[First@steps, ImageSize -> 10000]}];

Format[d[f_, x_], TraditionalForm] := Module[{paren, boxes},
	paren = MatchQ[f,Plus[_,__]];
	boxes = RowBox[{f}];
	If[paren,
		boxes = RowBox[{"(", boxes, ")"}]
	];
	boxes = RowBox[{FractionBox["\[DifferentialD]", RowBox[{"\[DifferentialD]", x}]], boxes}];
	DisplayForm[boxes]
];

dSpecificRules = {d[x_, x_] :> 1, d[(f_)[x_], x_] :> D[f[x], x],
                 d[(a_)^(x_), x_] :> D[a^x, x] /; FreeQ[a, x]};

dConstantRule = d[c_, x_] :> 0 /; FreeQ[c, x];

dLinearityRule = {d[f_ + g_, x_] :> d[f, x] + d[g, x],
                 d[c_ f_, x_] :> c d[f, x] /; FreeQ[c, x]};

dPowerRule = {d[x_, x_] :> 1, d[(x_)^(a_), x_] :> a*x^(a - 1) /; FreeQ[a, x]};

dProductRule = d[f_ g_, x_] :> d[f, x] g + f d[g, x];

dQuotientRule = d[(f_)/(g_), x_] :> (d[f, x]*g - f*d[g, x])/g^2;

dInverseFunctionRule := d[InverseFunction[f_][x_], x_] :>
                      1/Derivative[1][f][InverseFunction[f][x]];

dChainRule = {d[(f_)^(a_), x_] :> a*f^(a - 1)*d[f, x] /; FreeQ[a, x],
             d[(a_)^(f_), x_] :> Log[a]*a^f*d[f, x] /; FreeQ[a, x],
             d[(f_)[g_], x_] :> (D[f[x], x] /. x -> g)*d[g, x],
             d[(f_)^(g_), x_] :> f^g*d[g*Log[f], x]};

$dRuleNames = {"Specific Rules", "Constant Rule", "Linearity Rule", "Power Rule",
              "Quotient Rule", "Product Rule", "Inverse Function Rule", "Chain Rule"};

displayStart[expr_] := CellPrint[
	Cell[BoxData[MakeBoxes[HoldForm[expr], TraditionalForm]], "Output",
		Evaluatable -> False, CellMargins -> {{Inherited, Inherited}, {10, 10}},
		CellFrame -> False, CellEditDuplicate -> False]];

displayDerivative[expr_, k_Integer] := CellPrint[
	Cell[BoxData[TooltipBox[RowBox[{InterpretationBox["=", Sequence[]], "  ",
		MakeBoxes[HoldForm[expr], TraditionalForm]}], "Differentation: " <> $dRuleNames[[k]],
		LabelStyle -> "TextStyling"]], "Output", Evaluatable -> False,
	CellMargins -> {{Inherited, Inherited}, {10, 10}},
	CellFrame -> False, CellEditDuplicate -> False]];

walkD::differentationError = "Failed to differentiate expression!";

walkD[f_, x_] := Module[{derivative, oldderivative, k},
	derivative = d[f, x]; displayStart[derivative];
	While[! FreeQ[derivative, d],
		oldderivative = derivative; k = 0;
		While[oldderivative == derivative,
			k++;
			If[k > Length@$dRuleNames,
				Message[walkD::differentationError];
				Return[D[f, x]];
			];
			derivative = derivative /. ToExpression["d" <> StringReplace[$dRuleNames[[k]], " " -> ""]]
		];
		displayDerivative[derivative, k]];
	D[f, x]
];


Format[int[f_,x_],TraditionalForm]:= (
	paren = MatchQ[f,Plus[_,__]];
	boxes = RowBox[{f}];
	If[paren,
		boxes = RowBox[{"(", boxes, ")"}]
	];
	boxes = RowBox[{boxes, "\[DifferentialD]", x}];
	boxes = RowBox[{"\[Integral]", boxes}];
	DisplayForm[boxes]
);

intSpecificRules = {int[(f_)[x_], x_] :> Integrate[f[x], x],
                   int[(a_)^(x_), x_] :> Integrate[a^x, x] /; FreeQ[a, x]};

intConstantRule = int[c_, x_] :> c*x /; FreeQ[c, x];

intLinearityRule = {int[f_ + g_, x_] :> int[f, x] + int[g, x],
                   int[c_ f_, x_] :> c int[f, x] /; FreeQ[c, x]};

intPowerRule = {int[x_, x_] :> x^2 / 2, int[1/x_, x_] :> Log[x], int[(x_)^(a_), x_] :> x^(a + 1)/(a + 1) /; FreeQ[a, x]};

intChainRule = int[a_ fd_[g_] gd_, x_] :> a (Integrate[fd[u], u] /. u -> g) /; D[g, x] == gd && FreeQ[a, x];

subst[f_, g_, x_] := "f(u) = " <> ToString @ f[u] <> "\nu = g(" <> ToString @ x <> ") = " ToString @ g <> "\ng'(" <> ToString @ x <> ") = " ToString @ D[g, x]

intSubstitutionRule = {
						int[(f_)^(a_), x_] :> {((Integrate[u^a, u] / d[f, x]) /. u -> f),
								subst[#^a &, f, x]
							}
							/; FreeQ[a, x] && FreeQ[D[f, x], x],

						int[(f_)^(a_) g_, x_] :> {((Integrate[u^a, u] / d[f, x]) * g /. u -> f),
								subst[#^a &, f, x]
							}
							/; FreeQ[a, x] && FreeQ[FullSimplify[D[f, x] / g], x],

						int[(a_)^(f_), x_] :> {(a ^ f)/(d[f, x] * Log[a]),
								subst[a^# &, f, x]
							}
							/; FreeQ[a, x] && FreeQ[D[f, x], x],

						int[(a_)^(f_) g_, x_] :> {(a ^ f)/(d[f, x] * Log[a]) * g,
								subst[a^# &, f, x]
							}
							/; FreeQ[a, x] && FreeQ[FullSimplify[D[f, x] / g], x],

						int[(f_)[g_], x_] :> {(Integrate[f[u], u] /. u -> g) / d[g, x],
								subst[f, g, x]
							}
							/; FreeQ[D[g, x], x],

						int[(f_)[g_] h_, x_] :> {(Integrate[f[u], u] /. u -> g) / d[g, x] * h,
								subst[f, g, x]
							}
							/; FreeQ[FullSimplify[D[g, x] / h], x]
					};

intIntegrationByParts = int[f_ gd_, x_] :> f * g - int[d[f, x] * g, x] /; D[g, x] == gd;

intProductRule = int[f_ g_, x_] :> int[f, x] g - int[int[f, x] * d[g, x], x];

$intRuleNames = {"Specific Rules", "Constant Rule", "Linearity Rule", "Power Rule", "Substitution Rule", "Product Rule"};

displayIntegral[expr_, k_Integer, extrainfo_String] := CellPrint[
  Cell[BoxData[TooltipBox[RowBox[{InterpretationBox["=", Sequence[]], "  ",
       MakeBoxes[HoldForm[expr], TraditionalForm]}], "Integration: " <> $intRuleNames[[k]] <> If[extrainfo == "", "", "\n" <> extrainfo],
     LabelStyle -> "TextStyling"]], "Output", Evaluatable -> False,
   CellMargins -> {{Inherited, Inherited}, {10, 10}},
   CellFrame -> False, CellEditDuplicate -> False]];

walkInt::integrationError = "Failed to integrate expression!";
walkInt::differentationError = "Failed to differentiate expression!";

walkInt[f_, x_] := Module[{integral, oldintegral, extrainfo, k, leafcounts, ruleused},
	integral = int[f, x]; displayStart[integral];
	leafcounts = {};
	ruleused = "";
	While[! FreeQ[integral, int],
		If[ruleused == "Product Rule",
			AppendTo[leafcounts, LeafCount @ integral];
			If[Length @ leafcounts >= 5 && OrderedQ @ Take[leafcounts, -5],
				Message[walkInt::integrationError];
				Return[Integrate[f, x]];
			];
		];
		extrainfo = "";
		oldintegral = integral; k = 0;
		While[oldintegral == integral,
			k++;
			If[k > Length@$intRuleNames,
				Message[walkInt::integrationError];
				Return[Integrate[f, x]];
			];
			integral = integral /. ToExpression["int" <> StringReplace[$intRuleNames[[k]], " " -> ""]];
			If[Head @ integral === List,
				extrainfo = First @ Cases[Last @ integral, _String];
				integral = First @ integral;
			];
		];
		ruleused = $intRuleNames[[k]];
		displayIntegral[integral, k, extrainfo];
		While[! FreeQ[integral, d],
			oldintegral = integral; k = 0;
			While[oldintegral == integral,
				k++;
				If[k > Length@$dRuleNames,
					Message[walkInt::differentationError];
					Return[Integrate[f, x]];
				];
				integral = integral /. ToExpression["d" <> StringReplace[$dRuleNames[[k]], " " -> ""]]
			];
			displayDerivative[integral, k];
		];
	];
	Integrate[f, x]
];

End[];

(*
  Make it possible to work with subscripted and overscripted variables.
  This needs to stay after the End call or it will fuck up the [esc]qu[esc] function.
*)

If[$FrontEnd =!= Null,
	Notation`AutoLoadNotationPalette = False;
	Needs["Notation`"];
];

If[$FrontEnd =!= Null,
	Symbolize[ParsedBoxWrapper[SubscriptBox["_", "_"]]];
	Symbolize[ParsedBoxWrapper[OverscriptBox["_","_"]]];
	Notation[ParsedBoxWrapper[\(\(\[LeftBracketingBar] expr_ \[RightBracketingBar]\)\_a_\%b_\)] \[DoubleLongLeftRightArrow]
	   ParsedBoxWrapper[\(intInterval[\(expr_, \({a_, b_}\)\)]\)]];
];
