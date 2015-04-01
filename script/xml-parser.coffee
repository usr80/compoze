xml2json = require 'xml2json'
fs = require 'fs'

fileName = '秒速五厘米'
xml = fs.readFileSync '../example/' + fileName + '.xml'

json = xml2json.toJson xml,{object:true}


song = json['score-partwise']

measures = []
Duration =
  '16th':    '16'
  '32th':    '32'
  'eighth':   '8'
  'quarter': 'q'
  'half':    'h'
song.part.measure.forEach (measure, i)->
  measures[i] = 'notes ' unless measures[i]
  chord = []
  duration = null
  measure.note.forEach (note)->
    temp = ''
    if chord.length>0 and not note.chord
      if chord.length is 1
       temp += chord[0] + ' '
      else
       temp += '(' + chord.join('+') + ') '
      if duration != note.type

        temp = (if Duration[duration] then (' :'+ Duration[duration]) else '') + ' ' + temp

      measures[i] += temp

      duration = note.type
      chord = []
    duration = note.type
    if note.rest
      chord.push '##'
    else
      chord.push note.notations.technical.fret + '/' + note.notations.technical.string

s = 'options player=true tempo=76 width=980\n'
measures.forEach (m)->
  # console.log m
  s += 'tabstave notation=true tablature=true\n' + m + '\n'


fs.writeFileSync '../example/' + fileName + '.md', s



