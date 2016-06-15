{***************************************************************************}
{                                                                           }
{           iORM - (interfaced ORM)                                         }
{                                                                           }
{           Copyright (C) 2016 Maurizio Del Magno                           }
{                                                                           }
{           mauriziodm@levantesw.it                                         }
{           mauriziodelmagno@gmail.com                                      }
{           https://github.com/mauriziodm/iORM.git                          }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}



unit iORM.Where.SqlItems.Interfaces;

interface

uses
  iORM.Interfaces, System.Rtti, iORM.Context.Map.Interfaces;

type

  IioSqlItemWhere = interface(IioSqlItem)
    ['{0916A6EC-167E-4CD2-8C0B-ADE755E5157B}']
    function GetSql(const AMap:IioMap): String;
    function GetSqlParamName(const AMap:IioMap): String;
    function GetValue(const AMap:IioMap): TValue;
    function HasParameter: Boolean;
  end;

implementation

end.