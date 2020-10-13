debugMode=false;
rtPlatform=null;
rtStartTime=-1;
rtEndTime=-1;
rtResult=null;
popUps=new Array();

function cachebuster() {
    return '?cachebuster='
	+'A'+Math.random().toString()
	+'B'+Math.random().toString()
	+'C'+Math.random().toString()
	+'D'+Math.random().toString();
}

function zeroPad2(number) {
    if(number<10) {
	return '0'+number.toString();
    } else {
	return number.toString();
    }
}

function niceTime(when) {
    var date;
    date=new Date(0);
    date.setUTCSeconds(when);
    return date.toUTCString();
}

function niceDuration(duration) {
    var hours, minutes, seconds;
    var hoursPad, minutesPad, secondsPad;
    hours=Math.floor(duration/3600);
    minutes=Math.floor((duration-hours*3600)/60);
    seconds=Math.floor(duration-hours*3600-minutes*60);
    return zeroPad2(hours)+':'+zeroPad2(minutes)+':'+zeroPad2(seconds);
}

function niceAge(whence) {
    var nowdate;
    var nowtime;
    var duration;
    nowdate=new Date();
    nowtime=nowdate.valueOf()/1000.0;
    duration=nowtime-whence;
    return niceDuration(duration);
   
}

function closeAll() {
  for(var i=0;i<popUps.length;i++) {
    element=document.getElementById(popUps[i]);
    element.className='compileinfo';
  }
}

function openCompile(id) {
    var oldurl=location.href;
    location.href='#'+id;
    history.replaceState(null,null,oldurl);
    // location.href = "#"+h;                 //Go to the target element.
    // history.replaceState(null,null,url);   //Don't like hashes. Changing it back.    window.location=
    //element=document.getElementById(id);
  //element.className='compileinfoshow';
    //  window.scrollTo(0,element.offsetTop);
}

function asId(text) {
  // Generate a reasonable css id based on some text.

  // Strings of anything other than alphanumeric and _ become a single _
  // Remove trailing underscores.
  // Prepend "id_"
  part='id_'+text.replace(/[^A-Za-z0-9_]+/g,'_');
  return part.replace(/_+$/g,'').replace(/__+/g,'_');
}

function cleanText(text) {
  return text.replace(/&/g,"&amp;").replace(/</g,"&lt;").
              replace(/\s+/g,"&nbsp;");
}

function cleanTest(text) {
  return text.replace(/&/g,"&amp;").replace(/</g,"&lt;").
      replace(/\s+/g,"&nbsp;").replace(/%/g,"<wbr>%<wbr>").
      replace(/@/g,"<wbr>@<wbr>").replace(/_/g,"<wbr>_<wbr>");
}

function toggleInfo(id) {
  element=document.getElementById(id);
  className=element.className;
  if(className=='testinfo') {
    element.className='testinfoshow';
  } else {
    element.className='testinfo';
  }
}

function topNotes() {
  return '<p>Source: <a href="regtest.txt">regtest.txt</a>.  Click on a test or repo for details.</p>'+
    '<p>Legend: <span class="repo">CHECKOUT</span> - '+
    'TEST <span class="passrow">PASSED</span> - '+
    'TEST <span class="failrow">FAILED</span> - '+
      'NEMS <span class="compileinfo">RECOMPILED</span></p>';
}

function itoggle(irow) {
  toggleInfo("detail"+irow);
}

function toggle1() {
  toggleInfo("detail1");
}

function tableHeading() {
  return '<table class="rtresult">'
    +'<tr class="head"><th>Action</th><th>Result</th>'
    +'<th class="thdetail">Details (click for more info)</th></tr>\n';
}

function makeRepoRow(rownum,repoPath,repoURL,repoRevision,repoInfo) {
  if(repoPath=='.') {
    repoPath='. (top of checkout)';
  }
  return '<tr class="repo" onclick="itoggle('+rownum+')">\n'+
    '  <td>'+repoPath+'</td>\n'+
    '  <td>rev '+repoRevision+'</td>\n'+
    '  <td>\n'+
    '    '+repoURL+'\n'+
    '    <ul class="testinfo" id="detail'+rownum+'">\n'+
    repoInfo+
    '    </ul>\n'+
    '  </td>\n'+
    '</tr>\n';
}

function makeTestRow(rownum,testName,testTime,testStatus,testDescr,testInfo) {
    if(testStatus=='PASS') {
          row='<tr class="passrow" onclick="itoggle('+rownum+')">\n';
    } else {
          row='<tr class="failrow" onclick="itoggle('+rownum+')">\n';
    }
    return row+
	'\n  <td class="testname">'+cleanTest(testName)+
	'</td>\n  <td class="teststatus">'+
	cleanText(testStatus)+'</td>\n  <td class="testmore"'+
	'>\n    <div class="testdescr">\n      '+
	cleanText(testDescr)+'\n    </div>\n'+
	'    <ul class="testinfo" id="detail'+rownum.toString()+
	'">\n'+testInfo+'\n    </ul>\n  </td>\n</tr>\n';
}

function receiveText(text,debugMode) {
  var lines=text.split(/[\n\r]+/);
  var mode='PRE';
  var line;
  var unknown='**unknown**';
  var compileMode=unknown;
  var testName=unknown;
  var testDescr=unknown;
  var testTime=unknown;
  var testStatus=unknown;
  var testInfo='';
  var row='';
  var startedTable=false;
  var numBad=0;
  var text='';
  var endtext='';
  var rownum=0;
  var sawDot=false; // Did I see repo path "." yet?
  var inCompileDiv=false;
  var compileTime=null;
  var compileClass=null;
  var compileStatus=null;
  var testEarlyStatus=null;
  var lineReports=0;

  for(var i=0;i<lines.length;i++) {
    line=lines[i];
    if(lineReports<300) {
        console.log('mode '+mode+' line: '+line);
        lineReports++;
    }
    if(-1!==line.search(/^\s*$/)) {
      // Ignore blank lines.
      continue;
    }
    if(mode=='PRE') {
      m=line.match(/^===.REGTEST BEGIN\s+\+(-?\d+)$/);
      if(m) {
	  mode='REGTEST';
	  rtStartTime=m[1];
	  continue;
      }
    } else if(mode=='REGTEST') {
      m=line.match(/^===!REGTEST (\S+) (\S+) ?(.*)/);
      if(m!=null) {
        if(m[1]=='PLATFORM') {
          rtPlatform=m[2];
	  if(m[3]) {
	      rtPlatform+=' '+m[3]
	  }
          continue;
        } else if(m[1]=='RESULT') {
          rtResult=m[2];
          continue;
        } else if(m[1]=='LOG' && m[2]=='BEGIN') {
          mode='LOG';
          if(!startedTable) {
            text+=tableHeading();
            startedTable=true;
          }
          continue;
        } else if(m[1]=='REPO' && m[2]=='BEGIN') {
          mode='REPO';
          repoInfo=null; // for detection of empty repo info in REPO mode
          if(!startedTable) {
            text+=tableHeading();
            startedTable=true;
          }
          continue;
        } else if(m[1]=='COMPILE') {
          mode='COMPILE';
          compileId=asId(m[2]);
          inCompileDiv=true;
          endtext+='<a name="'+compileId+'"></a>'
                  +'<h1 id='+compileId+'> Compile NEMS Executable for '+m[2]+'</h1>';
          continue;
        } else if(m[1]=='END') {
	    rtEndTime=m[2];
	    continue;
	}
      }
    } else if(mode=='COMPILE') {
	if(line.match(/^===!REGTEST COMPILE END/)) {
	    mode='REGTEST';
	    if(inCompileDiv) {
		inCompileDiv=false;
	    }
	    continue;
	} else {
	    endtext+=cleanText(line)+'<br>';
	    continue;
	}
    } else if(mode=='REPO' || mode=='GIT_BRANCH') {
      // Check for repo name line
      if(-1!=line.search(/^===!REGTEST REPO END/)) {
          console.log('saw REGTEST REPO END in mode '+mode);
        if(( repoInfo!==null && (repoPath!='.' || !sawDot) ) || mode=='GIT_BRANCH') {
          rownum++;
          console.log('makeRepoRow after REGTEST REPO END');
          text+=makeRepoRow(rownum,repoPath,repoURL,repoRevision,repoInfo);
          sawDot=( sawDot || repoPath=='.')
        }
        mode='REGTEST';
        continue;
      }
      if(-1!=line.search(/^REPO TOP:/)) {
          mode='GIT_BRANCH';
          repoPath='.';
          repoURL='';
          repoRevision='';
          repoInfo='';
          continue;
      }
      m=line.match(/^Entering '([^\']+)'/);
      if(m!==null) {
          console.log('makeRepoRow after Entering');
          rownum++;
          text+=makeRepoRow(rownum,repoPath,repoURL,repoRevision,repoInfo);
          mode='GIT_BRANCH';
          repoPath=m[1];
          repoURL='';
          repoRevision='';
          repoInfo='';
          continue;
      }
      if(mode=='GIT_BRANCH') {
          repoInfo+=cleanText(line)+'<br>\n';
          m=line.match(/^Fetch URL: (\S+)/);
          if(m!==null) {
              repoURL=m[1];
              continue;
          }
          m=line.match(/^([^\(]\S+)\s+([a-zA-Z0-9]+)\s+/);
          if(m!==null) {
              repoPath='branch '+m[1];
              repoRevision=m[2];
              continue;
          }
          m=line.match(/^\([^\)]*\)\s+([a-zA-Z0-9]+)\s+/);
          if(m!==null) {
            repoPath='no branch';
            repoRevision=m[1];
            continue;
          }
          if(line.match(/^\s*$/)) {
              mode='REPO';
              continue;
          }
      }
      m=line.match(/^Path: (\S+)/);
      if(m!==null) {
        if(repoInfo!==null && (repoPath!='.' || !sawDot) ) {
          rownum++;
          text+=makeRepoRow(rownum,repoPath,repoURL,repoRevision,repoInfo);
          sawDot=( sawDot || repoPath=='.')
        }
        repoPath=m[1];
        repoURL='';
        repoRevision='';
        repoInfo='<li>'+cleanText(line)+'</li>\n';
        continue;
      }
      m=line.match(/^([^:]+): (.*)/);
      if(m!==null) {
        repoInfo+='<li>'+cleanText(line)+'</li>\n';
        if(m[1]=='URL') {
          repoURL=m[2];
        }
        if(m[1]=='Revision') {
          repoRevision=m[2];
        }
        continue;
      }
      // Other lines can be ignored
      continue;
    } else if(mode=='LOG' || mode=='TEST' || mode=='BETWEEN_TESTS') {
	//Test gfs_gocart_nemsio starting at Tue Dec 13 01:36:17 UTC 2016 (GFS_GOCART with NEMSIO)
      // Check for test start line.
	if(mode=='LOG') {
	    m=line.match(/BUILD ([^:]+): ([A-Z]+)/);
	    if(m!==null) {
		rownum++;
		compileId=m[1];
		compileClass='compile';
		compileStatus=m[2];
		if(compileStatus!='SUCCEEDED') {
		    compileClass='compilefail';
		}
		text+='<tr class="'+compileClass+'" onclick="openCompile('
		    +"'"+asId(compileId)+"'"+')">\n'
		    +'  <td>COMPILE</td>\n<td>'
		    +cleanText(compileStatus)+'</td>\n  <td>'
		    +cleanText(compileId)+'</td>\n</tr>\n';
		continue;
	    }
	    if(-1!=line.search(/TEST #|WORKFLOW START|WORKFLOW REPORT/)) {
		// Can ignore these in LOG mode
		continue;
	    }
	}
	// TEST #7: PASS
	m=line.match(/TEST #[0-9]+: ([A-Z]+)/);
	if(m!==null) {
	    testEarlyStatus=m[1];
	    continue;
	}
	// Test fv3_appbuilder starting at Thu Apr 5 02:11:36 GMT 2018
	// (Compare FV3 with the NEMSAppBuilder against the previous
	// trunk version)
	m=line.match(/Test ([^\)]+) starting at ([^\(]+) \(([^\)]+)\)/);
	if(m!==null) {
	    mode='TEST';
	    if(testName!=unknown) {
		rownum++;
		text+=makeTestRow(rownum,testName,testTime,testStatus,testDescr,testInfo);
	    }
	    testName=m[1];
	    testTime=m[2];
	    testDescr=m[3];
	    testInfo='';
	    testStatus='FAIL';
	    if(testEarlyStatus!==null) {
		testStatus=testEarlyStatus;
		testEarlyStatus=null;
	    }
	    continue;
	}
	if(-1!=line.search(/TEST PASSED AT/)) {
	    testInfo=testInfo.concat('\n    <li>\n      ');
	    testInfo=testInfo.concat(cleanText(line));
	    testInfo=testInfo.concat('\n    </li>\n');
	    testStatus='PASS';
	    mode='BETWEEN_TESTS';
	    continue;
	}
	if (-1!=line.search(/^===!REGTEST LOG END/)) {
	    mode='REGTEST';
	    if(testName!=unknown) {
		rownum++;
		text+=makeTestRow(rownum,testName,testTime,testStatus,testDescr,testInfo);
		testName=unknown;
		testTime=unknown;
		testDescr=unknown;
		testInfo='';
		testStatus='FAIL';
	    }
	    continue;
	}
	if(mode=='TEST') {
	    testInfo=testInfo.concat('\n    <li>\n      ');
	    testInfo=testInfo.concat(cleanText(line));
	    testInfo=testInfo.concat('\n    </li>\n');
	    continue;
	}
    }

    if(debugMode && numBad<100) {
      numBad++;
      if(!startedTable) {
        text+=tableHeading();
        startedTable=true;
      }
      text+='<tr class="badline"><td>mode='+cleanText(mode)+'</td><td>BAD LINE</td><td>'+cleanText(line)+'</td></tr>\n';
    }
  }
  if(startedTable) {
    text+='</table>\n';
  }

  toptext='<h1>'+cleanText(rtPlatform)+' Regression Tests: '+
      cleanText(rtResult)+'</h1>\n'
      + '<p>Start time: '+niceTime(rtStartTime)+'&nbsp;(age '+niceAge(rtStartTime)+')</p>'
      +'<p>End time: '+niceTime(rtEndTime)+'&nbsp;(age '+niceAge(rtEndTime)+')</p>'
      +'<p>Duration: '+niceDuration(rtEndTime-rtStartTime)+'</p>'
      +topNotes();

  document.body.innerHTML=toptext+text+endtext;
}

function readTextFile(filename) {
  var reader=new XMLHttpRequest();
  reader.open("GET",filename+cachebuster(),true);
  reader.onreadystatechange=function () {
    if(reader.readyState==4 && reader.status==200) {
      receiveText(reader.responseText,debugMode);
    }
  }
  reader.send(null);
}

function splashScreen() {
  document.body.innerHTML="<h1>Loading...</h1>"+
    "<p>Please wait.  Loading regtest.txt...</p>";
}

window.onload=function() {
  splashScreen();
  readTextFile("regtest.txt");
}