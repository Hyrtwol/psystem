{*      COMPARE - Compare two text files and report their differences.
*
*       Copyright (C) 1977, 1978
*       James F. Miner
*       Social Science Research Facilities Center
*       University of Minnesota
*
*       General permission to make fair use in non-profit activities
*       of all or part of this material is granted provided that
*       this notice is given. To obtain permission for other uses
*       and/or machine readable copies write to:
*
*               The Director
*               Social Science Research Facilities Center
*               25 Blegen Hall
*               269 19th Ave. So.
*               University of Minnesota
*               Minneapolis, Minnesota  55455
*               U S A
}


{*      Compare is used to display on "Output" the differences
*       between two similar texts ("Filea" and "Fileb"). Notable
*       characteristics are:
*
*       - Compare is line oriented. The smallest unit of comparison
*         is the text line (ignoring trailing blanks). The present
*         implementation has a fixed maximum line length.
*
*       - By manipulating a program parameter, the user can affect
*         Compare's sensitivity to the "locality" of differences.
*         More specifically this parameter, "Minlinesformatch",
*         specifies the number of consecutive lines on each file
*         which must match in order that they be considered as
*         terminating the prior mismatch.  A large value of
*         "Minlinesformatch" tends to produce fewer but larger
*         mismatches than does a small value.  The value six appears
*         to give good results on Pascal source files but may be
*         inappropriate for other applications.
*
*         If compare is to be used as a general utility program,
*         "Minlinesformatch" should be treated as a program
*         parameter of some sort.  It is declared as a constant here
*         for portability's sake.
*
*         Another program parameter (constant), "Markunequalcolumns",
*         specifies that when unequal lines are found, each line from
*         filea is printed next to its corresponding line from fileb,
*         and unequal columns are marked.  This option is particularly
*         useful for fixed-format data files.  Notes: Line pairing is
*         not attempted if the mismatching sections are not the same
*         number of lines on each file. It is not currently very smart
*         about ASCII control characters like tab. (W.Kempton, Nov 78)
*
*       - Compare employs a simple backtracking search algorithm to
*         isolate mismatches from their surrounding matches.  This
*         requires (heap) storage roughly proportional to the size
*         of the largest mismatch, and time roughly proportional to
*         the square of the size of the mismatch for each mismatch.
*         For this reason it may not be feasible to use Compare on
*         files with very long mismatches.
*
*       - To the best of the author's knowledge, Compare utilizes
*         only features of Standard Pascal.
*
*       Modified for UCSD Pascal by T.S. Beck - 9 Jun 80.
}


program compare;

  const
    version = '1.3   (7 Nov 78)';
    linelength = 120;             { MAXIMUM SIGNIFICANT INPUT LINE LENGTH }
    minlinesformatch = 3;         { NUMBER OF CONSECUTIVE EQUIVALENT }
                                  { LINES TO END A MIS-MATCH }
    markunequalcolumns = true;    { IF UNEQUAL LINES ARE TO BE PAIRED, }
                                  {  AND UNEQUAL COLUMNS MARKED }

  type
    linepointer = ^line;
    line =                        { SINGLE LINE BUFFER }
      packed record
        nextline : linepointer;
        length : 0..linelength;
        image : packed array [1..linelength] of char
      end;

    stream =                      { BOOKKEEPING FOR EACH INPUT FILE }
      record
        name : char;
        cursor, head, tail : linepointer;
        cursorlineno, headlineno, taillineno : integer;
        endfile : boolean
      end;

    var
      filea, fileb : text;
      out : interactive;
      filename : string[24];
      a, b : stream;
      match : boolean;
      endfile : boolean;          { SET IF END OF STREAM A OR B }

      templine :                  { USED BY READLINE }
        record
          length : integer;
          image : array [0..linelength] of char
        end;

      freelines : linepointer;    { FREE LIST OF LINE BUFFERS }

      same : boolean;             { FALSE IF NO MIS-MATCHES OCCUR }
      linestoolong : boolean;     { FLAG IF SOME LINES NOT COMPLETELY CHECKED }


    procedure comparefiles;

      function endstream(var x : stream) : boolean;
      begin { ENDSTREAM }
        endstream := (x.cursor = nil) and x.endfile
      end;  { ENDSTREAM }

      procedure mark(var x : stream);

        { CAUSES BEGINNING OF STREAM TO BE POSITIONED BEFORE }
        { CURRENT STREAM CURSOR.  BUFFERS GET RECLAIMED, LINE }
        { COUNTERS RESET, ETC. }

        var
          p : linepointer;

        begin { MARK }
          with x do
            if head <> nil then
              begin
                while head <> cursor do { RECLAIM BUFFER }
                  begin
                    with head^ do
                      begin  p := nextline;
                        nextline := freelines;  freelines := head
                      end;
                    head := p
                  end;
                headlineno := cursorlineno;
                if cursor = nil then
                  begin  tail := nil;  taillineno := cursorlineno  end
              end
        end;  { MARK }

        procedure movecursor(var x : stream;  var filex : text);

          { FILEX IS THE INPUT FILE ASSOCIATED WITH STREAM X.  THE }
          { CURSOR FOR X IS MOVED FORWARD ONE LINE, READING FROM X }
          { IF NECESSARY, AND INCREMENTING THE LINE COUNT.  ENDFILE }
          { IS SET IF EOF IS ENCOUNTERED ON EITHER STREAM. }

          procedure readline;
            var
              newline : linepointer;
              c, c2 : 0..linelength;
          begin { READLINE }
            if not x.endfile then
              begin
                c := 0;
                while not eoln(filex) and (c < linelength) do
                  begin
                    c := c + 1;
                    templine.image[c] := filex^;
                    get(filex)
                  end;
                if not eoln(filex) then  linestoolong := true;
                readln(filex);
                while templine.image[c] = ' ' do c := c - 1;
                if c < templine.length then
                  for c2 := c+1 to templine.length do
                    templine.image[c2] := ' ';
                templine.length := c;
                newline := freelines;
                if newline = nil then new(newline)
                else  freelines := freelines^.nextline;
                for c2 := 1 to linelength do
                  newline^.image[c2] := templine.image[c2];
                newline^.length := c;
                newline^.nextline := nil;
                if x.tail = nil then
                  begin  x.head := newline;
                    x.taillineno := 1;  x.headlineno := 1
                  end
                else
                  begin x.tail^.nextline := newline;
                    x.taillineno := x.taillineno + 1
                  end;
                x.tail := newline;
                x.endfile := eof(filex);
              end
          end;  { READLINE }

        begin { MOVECURSOR }
          if x.cursor <> nil then
            begin
              if x.cursor = x.tail then readline;
              x.cursor := x.cursor^.nextline;
              if x.cursor = nil then endfile := true;
              x.cursorlineno := x.cursorlineno + 1
            end
          else
            if not x.endfile then { BEGINNING OF STREAM }
              begin
                readline; x.cursor := x.head;
                x.cursorlineno := x.headlineno
              end
            else  { END OF STREAM }
              endfile := true;
        end;  { MOVECURSOR }

        procedure backtrack(var x : stream;  var xlines : integer);

          { CAUSES THE CURRENT POSITION OF STREAM X TO BECOME THAT }
          { OF THE LAST MARK OPERATION.  I.E., THE CURRENT LINE   }
          { WHEN THE STREAM WAS MARKED LAST BECOMES THE NEW CURSOR. }
          { XLINES IS SET TO THE NUMBER OF LINES FROM THE NEW CURSOR }
          { TO THE OLD CURSOR, INCLUSIVE. }

        begin { BACKTRACK }
          xlines := x.cursorlineno + 1 - x.headlineno;
          x.cursor := x.head;  x.cursorlineno := x.headlineno;
          endfile := endstream(a) or endstream(b)
        end;  { BACKTRACE }

        procedure comparelines(var match : boolean);

          { COMPARE THE CURRENT LINES OF STREAMS A AND B, RETURNING }
          { MATCH TO SIGNAL THEIR (NON-) EQUIVALENCE.  EOF ON BOTH STREAMS }
          { IS CONSIDERED A MATCH, BUT EOF ON ONLY ONE STREAM IS A MISMATCH }

        begin { COMPARELINES }
          if (a.cursor = nil) or (b.cursor = nil) then
            match := endstream(a) and endstream(b)
          else
            begin
              match := (a.cursor^.length = b.cursor^.length);
              if match then
                match := (a.cursor^.image = b.cursor^.image)
            end
        end;  { COMPARELINES }

        procedure findmismatch;
        begin { FINDMISMATCH }
          { NOT ENDFILE AND MATCH }
          repeat  { COMPARENEXTLINES }
            movecursor(a, filea); movecursor(b,fileb);
            mark(a); mark(b);
            comparelines(match)
          until endfile or not match;
        end;  { FINDMISMATCH }

        procedure findmatch;
          var
            advanceb : boolean; { TOGGLE ONE-LINE LOOKAHEAD BETWEEN STREAMS }

          procedure search(var x : stream; { STREAM TO SEARCH }
                           var filex : text;
                           var y : stream; { STREAM TO LOOKAHEAD }
                           var filey : text);

            { LOOK AHEAD ONE LINE ON STREAM Y, AND SEARCH FOR THAT LINE }
            { BACKTRACKING ON STREAM X. }

            var
              count : integer; { NUMBER OF LINES BACKTRACKED ON X }

            procedure checkfullmatch;
              { FROM THE CURRENT POSITIONS IN X AND Y, WHICH MATCH, }
              { MAKE SURE THAT THE NEXT MINLINESFORMATCH-1 LINES ALSO }
              { MATCH, OR ELSE SET MATCH := FALSE.  }
              var
                n : integer;
                savexcur, saveycur : linepointer;
                savexline, saveyline : integer;
            begin { CHECKFULLMATCH }
              savexcur := x.cursor;  saveycur := y.cursor;
              savexline := x.cursorlineno;  saveyline := y.cursorlineno;
              comparelines(match);
              n := minlinesformatch - 1;
              while match and (n <> 0) do
                begin  movecursor(x, filex);  movecursor(y, filey);
                  comparelines(match);  n := n - 1;
                end;
              x.cursor := savexcur;  x.cursorlineno := savexline;
              y.cursor := saveycur;  y.cursorlineno := saveyline;
            end;  { CHECKFULLMATCH }

          begin { SEARCH }
            movecursor(y, filey);  backtrack(x, count);
            checkfullmatch;  count := count - 1;
            while (count <> 0) and not match do
              begin
                movecursor(x, filex);  count := count - 1;
                checkfullmatch
              end
          end;  { SEARCH }

          procedure printmismatch;
            var
              emptya, emptyb : boolean;

            procedure writeoneline(name : char; l : integer; p : linepointer);
            begin  { WRITEONELINE }
                  write(out,'   ', name, l:5,'  ');
                  if p^.length = 0 then writeln(out)
                  else writeln(out,p^.image : p^.length);
            end;  { WRITEONELINE }

            procedure writetext(var x : stream);
              { WRITE FROM X.HEAD TO ONE LINE BEFORE X.CURSOR }
              var
                p, q : linepointer;  lineno : integer;
            begin { WRITETEXT }
              p:=x.head;  q:=x.cursor;   lineno:=x.headlineno;
              while (p <> nil) and (p <> q) do
                begin
                  writeoneline( x.name, lineno, p);
                  p := p^.nextline;
                  lineno := lineno + 1;
                end;
              if p = nil then writeln(out,' *** eof ***');
              writeln(out)
            end;  { WRITETEXT }

            procedure writepairs( pa, pb : linepointer;  la, lb : integer);
              { THIS WRITES FORM THE HEAD TO THE CURSOR, LIKE PROCEDURE }
              { WRITETEXT.  UNLIKE PROCEDURE WRITETEXT, THIS WRITES FROM }
              { BOTH FILES AT ONCE, COMPARES COLUMNS WITHIN LINES, AND MARKS }
              { UNEQUAL COLUMNS. }
            var
              tempa, tempb : array [1..linelength] of char;
              col, maxcol  : integer;
            begin  { WRITEPAIRS }
              repeat
                writeoneline('a', la, pa);   writeoneline('b', lb, pb);
                for col := 1 to linelength do
                  begin
                    tempa[col] := pa^.image[col];
                    tempb[col] := pb^.image[col]
                  end;
                if  pa^.length > pb^.length
                        then maxcol := pa^.length else maxcol := pb^.length;
                write(out,' ': 11);
                  { 11 spaces used for file name and line number }
                for col := 1 to maxcol do
                    if tempa[col] = tempb[col] then write(out,' ')
                    else write(out,'^');
                writeln(out);  writeln(out);
                pa := pa^.nextline;  la := la + 1;
                pb := pb^.nextline;  lb := lb + 1;
              until (pa = a.cursor) or (pa = nil);
            end;  { WRITEPAIRS }

            procedure writelineno(var x : stream);
              var
                f, l : integer;
            begin { WRITELINENO }
              f := x.headlineno;  l := x.cursorlineno - 1;
              write(out,'line');
              if f = l then write(out,' ', f:1)
              else write(out,'s ', f:1, ' thru ', l:1);
              if x.cursor = nil then write(out,' (before eof)');
            end;  { WRITELINENO }

            procedure printextratext(var x , y : stream);

            begin { PRINTEXTRATEXT }
              write(out,' extra text:  on file', x.name, ', ');

              if y.head = nil then
                writeln(out,' before eof on file', y.name)
              else
                writeln(out,' between lines ', y.headlineno-1:1, ' and ',
                        y.headlineno:1, ' of file', y.name);
              writeln(out);
              writetext(x)
            end;  { PRINTEXTRATEXT }

          begin { PRINTMISMATCH }
            writeln(out,' ':11, '**********************************');
            emptya := (a.head = a.cursor);
            emptyb := (b.head = b.cursor);
            if emptya or emptyb then
              if emptya then printextratext(b, a)
              else printextratext(a, b)
            else
              begin
                write(out,' mismatch:   ');
                write(out,' filea, ');  writelineno(a);
                write(out,'   not equal to   ');
                write(out,' fileb, ');  writelineno(b);  writeln(out,':');
                writeln(out);
                if markunequalcolumns and ((a.cursorlineno - a.headlineno) =
                  (b.cursorlineno - b.headlineno))
                then
                  writepairs(a.head, b.head, a.headlineno, b.headlineno)
                else
                  begin  writetext(a);  writetext(b)  end
              end
          end;  { PRINTMISMATCH }

        begin { FINDMATCH }
          { NOT MATCH }
          advanceb := true;
          repeat
            if not endfile then advanceb := not advanceb
            else advanceb := endstream(a);
            if advanceb then search(a, filea, b, fileb)
              else search(b, fileb, a, filea)
          until match;
          printmismatch;
        end;  { FINDMATCH }

      begin { COMPAREFILES }
        match := true;  { I.E., BEGINNINGS-OF-FILES MATCH }
        repeat
          if match then findmismatch else begin same := false; findmatch end
        until endfile and match;
        { MARK(A);  MARK(B);   MARK END OF FILES, THEREBY DISPOSING BUFFERS }
      end;  { COMPAREFILES }

      procedure initialize;

        procedure initstream(fid : char; var x : stream; var filex : text);

        var
          count, i : integer;

        begin { INITSTREAM }
          with x do
            begin
              cursor := nil;  head := nil;  tail := nil;
              cursorlineno := 0; headlineno := 0;  taillineno := 0
            end;
          repeat
            write('Type name of file ',fid,': ');
            readln(filename);
            count := length(filename);
            if count = 0 then exit(compare);
            for i := 1 to count do
              if filename[i] in ['a'..'z'] then
                filename[i] := chr(ord(filename[i]) - 32);
            if (pos('.TEXT',filename) = 0) and (filename[count] <> '.') and
              (count < 19) then filename := concat(filename,'.TEXT');
            {$i-}
            reset(filex,filename)
            {$i+}
          until ioresult = 0;
          writeln(out,' file',fid,': ',filename);
          x.endfile := eof(filex);
        end;  { INITSTREAM }


      begin { INITIALIZE }
        initstream('a',a, filea);
        initstream('b',b, fileb);
        writeln(out);
        endfile := a.endfile or b.endfile;
        a.name := 'a';  b.name := 'b';
        linestoolong := false;
        freelines := nil;
        templine.length := linelength;
        templine.image[0] := 'x';  { SENTINEL }
      end; {INITIALIZE}


    begin {COMPARE}
      repeat
        write('Type output file name: '); readln(filename);
        if length(filename) = 0 then exit(compare);
        {$i-}
        reset(out,filename)
        {$i+}
      until ioresult = 0;
      if (filename = '#8:') or (filename = 'REMOTE:') then
        write(out,chr(27),'u',chr(24)); { set H14 printer to 96 char. }
      writeln(out,'     compare.  version ', version);
      writeln(out);
      writeln(out,' match criterion = ', minlinesformatch:1, ' lines.');
      writeln(out);
      initialize;
      if a.endfile then writeln(out,' filea is empty.');
      if b.endfile then writeln(out,' fileb is empty.');
      if not endfile then
        begin  same := true;
          comparefiles;
          if same then writeln(out,' no differences.');
          if linestoolong then
            begin     writeln(out);
              writeln(out,' WARNING:  some lines were longer than ',
                      linelength:1, ' characters.');
              writeln(out,'           they were not compared past that point.');
            end;
        end
    end.  { COMPARE }
