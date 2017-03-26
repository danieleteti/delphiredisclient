// *************************************************************************** }
//
// Delphi REDIS Client
//
// Copyright (c) 2015-2017 Daniele Teti
//
// https://github.com/danieleteti/delphiredisclient
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit RandomUtilsU;

interface

const
  FirstNames: array [0 .. 9] of string = (
    'Daniele',
    'Debora',
    'Mattia',
    'Jack',
    'James',
    'William',
    'Joseph',
    'David',
    'Charles',
    'Thomas'
    );

  LastNames: array [0 .. 9] of string = (
    'Smith',
    'JOHNSON',
    'Williams',
    'Brown',
    'Jones',
    'Miller',
    'Davis',
    'Wilson',
    'Martinez',
    'Anderson'
    );

  Countries: array [0 .. 9] of string = (
    'Italy',
    'New York',
    'Illinois',
    'Arizona',
    'Nevada',
    'UK',
    'France',
    'Germany',
    'Norway',
    'California'
    );

function GetRndFirstName: String;
function GetRndLastName: String;
function GetRndCountry: String;

implementation

function GetRndCountry: String;
begin
  Result := Countries[Random(10)];
end;

function GetRndFirstName: String;
begin
  Result := FirstNames[Random(10)];
end;

function GetRndLastName: String;
begin
  Result := LastNames[Random(10)];
end;

end.
