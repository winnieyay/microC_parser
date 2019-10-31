/*	Definition section */
%{
#include "define.h" 
#include "stdio.h"
#include "string.h"

Table *current_table = NULL;
int count_for_table = 0;

extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex
extern int final_flag;
extern int error_flag;
extern int dump_flag;
extern char error_msg[100][1000];
extern int num;

/* Symbol table function - you can add new function if needed. */
int lookup_symbol(Table *table, char *name);
void create_symbol();
void insert_symbol(Table *table, char *name, char* type, char* kind, char* attribute);
void dump_symbol();
int check_flag(char *v);
int check_redeclared(Table *table,char* name,char* kind);
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    struct Value value;
    char* type;
}

/* Token without return */
%token PRINT
%token SEMICOLON QUOTA COMMA
%token IF ELSE FOR WHILE AND OR NOT
%token ADD SUB MUL DIV MOD INC DEC
%token C_COMMENT
%token CPP_COMMENT
%token EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token MT LT MTE LTE
%token LB RB LCB RCB LSB RSB 
%token RET

/* Token with return, which need to sepcify type */
%token <type> INT FLOAT BOOL STRING VOID
%token <value> ID 
%token <value> I_CONST F_CONST STR_CONST
%token <value> TRUE FALSE
/* Nonterminal with return, which need to sepcify type */
%type <type> type
%type <value> expr and_expr or_expr comparison_expr addition_expr multiplication_expr postfix_expr parenthesis_clause
%type <value> bool constant

/* Yacc will start at this nonterminal */
%start program
/* Grammar section */
%%
program
    : program stat
    | 
;
stat
    : declaration
    | compound_stat
    | expression_stat
    | print_function
    | func
    | error
;
declaration
    : type ID SEMICOLON {
            insert_symbol(current_table, $2.id_name, $1, "variable", "");
        }
    | type ID ASGN expr SEMICOLON {
            insert_symbol(current_table, $2.id_name, $1, "variable", "");
        }
;
compound_stat
    : if_stat
    | for_stat
    | while_stat
    | assign_stat
;
type
    : INT { $$ = $1; }
    | FLOAT { $$ = $1; }
    | BOOL  { $$ = $1; }
    | STRING { $$ = $1; }
    | VOID { $$ = $1; }
;
if_stat
    : IF expr block_list
    | IF expr block_list ELSE block_list
    | IF expr block_list ELSE if_stat block_list
;
block_list
    : LCB{ create_symbol(); } program RCB { dump_flag = 1; }
;
for_stat
    : FOR expr block_list
;
while_stat
    : WHILE expr block_list
;
assign_stat
    : ID{
        if(check_flag($1.id_name) == 1){
                sprintf(error_msg[num], "Undeclared variable %s", $1.id_name);
                num++;
                error_flag = 1;
        }
    } assign_op expr SEMICOLON
;
expression_stat
    : expr SEMICOLON
    | SEMICOLON
;
expr
    : or_expr { $$ = $1; }
;
or_expr
    : and_expr { $$ = $1; }
    | or_expr OR and_expr
;
comparison_expr
    : addition_expr { $$ = $1; }
    | comparison_expr cmp_op addition_expr
;
and_expr
    : comparison_expr { $$ = $1;}
    | and_expr AND comparison_expr
;
addition_expr
    : multiplication_expr { $$ = $1; }
    | addition_expr add_op multiplication_expr
;
multiplication_expr
    : postfix_expr { $$ = $1; }
    | multiplication_expr mul_op postfix_expr
;
postfix_expr
    : parenthesis_clause { $$ = $1; }
    | parenthesis_clause post_op
;
parenthesis_clause
    : constant { $$ = $1; }
    | ID { $$ = $1;
	if(check_flag($1.id_name) == 1){
                 sprintf(error_msg[num], "Undeclared variable %s", $1.id_name);
		 num++;
                 error_flag = 1;
         }
    }
    | LB expr RB { $$ = $2; }
    | bool { $$ = $1;}
;
print_function
    : PRINT LB print_check RB SEMICOLON
;
print_check
    :ID{
        if(check_flag($1.id_name) == 1){
                 sprintf(error_msg[num], "Undeclared variable %s", $1.id_name);
                num++;
                error_flag = 1;
         }
    }
    | QUOTA STR_CONST QUOTA
; 
func
    : ID{
        if(check_flag($1.id_name) == 1){
                 sprintf(error_msg[num], "Undeclared function %s", $1.id_name);
                num++;
                error_flag =  1;
         }

    } LB arg RB SEMICOLON
    | type ID{
            insert_symbol(current_table, $2.id_name, $1, "function", "");
        } LB{ create_symbol(); } type_arg RB func_body
;
func_body
    :LCB program return_check RCB { dump_flag = 1; }
;
return_check
    :RET expr SEMICOLON
    |
;
type_arg
    : type_arg COMMA type ID  { insert_symbol(current_table, $4.id_name, $3, "parameter", $3); } 
    | type ID { insert_symbol(current_table, $2.id_name, $1, "parameter", $1); }
    |
;
arg
    : arg COMMA ID {
    	if(check_flag($3.id_name) == 1){
                sprintf(error_msg[num], "Undeclared variable %s", $3.id_name);
                num++; 
		error_flag = 1;
         }
 
    }
    | ID {
    	if(check_flag($1.id_name) == 1){
                sprintf(error_msg[num], "Undeclared variable %s", $1.id_name);
                num++; 
		error_flag = 1;
         }

    }
    |
;
bool
    : TRUE
    | FALSE
;
add_op
    : ADD
    | SUB
;
mul_op
    : MUL
    | DIV
    | MOD
;
cmp_op
    : MT
    | LT
    | MTE
    | LTE
    | EQ
    | NE
;
assign_op
     : ASGN
     | ADDASGN
     | SUBASGN
     | MULASGN
     | DIVASGN
     | MODASGN
;
post_op
    : INC
    | DEC
;
constant
    : I_CONST { $$ = $1; }
    | F_CONST { $$ = $1; }
    | QUOTA STR_CONST QUOTA { $$ = $2; }
;
%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
    yyparse();
    if(final_flag == 0) {
        dump_symbol();
        printf("\n Total lines: %d \n",yylineno);
    }
    return 0;
}
int check_flag(char* v){
	Table *tmp = current_table;
	while( tmp != NULL){
		if(lookup_symbol(tmp, v) == 0){
		    return 0;
		}
		else{
		    tmp = tmp->prev;
		}
	}
	return 1;
}
void yyerror(char *get_msg)
{
    
	if(strcmp(get_msg, "syntax error") == 0) {
        	if(final_flag == 1){
       			 printf("\n|--------------------------------------------------|\n");
       			 printf("| Error found in line %d: %s\n", yylineno, buf);
       			 printf("| %s", get_msg);
	       		 printf("\n|--------------------------------------------------|\n\n");
		}
		else{
			final_flag = 1;
		}
    	} 	
    	else {
        printf("\n|--------------------------------------------------|\n");
        printf("| Error found in line %d: %s\n", yylineno, buf);
        printf("| %s", get_msg);
        printf("\n|--------------------------------------------------|\n\n");
    	}
}
void create_symbol() {
    Table *new_table = malloc(sizeof(Table));
    new_table->head = malloc(sizeof(Ent));
    if (current_table == NULL) {
        new_table->table_count = count_for_table;
        new_table->head->next = NULL;
        new_table->tail = new_table->head;
        new_table->prev = NULL;
	new_table->entry_count = 0;
        current_table = new_table;
    }
    else {
        new_table->table_count = count_for_table;
        new_table->head->next = NULL;
        new_table->tail = new_table->head;
        new_table->prev = current_table;
        current_table = new_table;
	new_table->entry_count = 0;
    }
    count_for_table ++;
}
int check_redeclared(Table *table,char* name,char* kind){
    if(lookup_symbol(table,name) == 0){
        if(kind == "variable"){
		sprintf(error_msg[num], "Redeclared variable %s", name);
	}
	else if(kind == "function"){
		sprintf(error_msg[num], "Redeclared function %s", name);
	}
	num++;
        return 1;
    }
    else{
	return 0;
    }

}
void insert_symbol(Table *table, char* name, char* type, char* kind, char* attribute) {
    if (current_table == NULL) {
        create_symbol();
        table = current_table;
    }
    //Redeclared
    error_flag = check_redeclared(table,name,kind);
    // first declared
    if(error_flag == 0){
        Ent *tmp = malloc(sizeof(Ent));
        char *get_attr = malloc(sizeof(char *));
	tmp->index = table->entry_count;
        tmp->name = name;
        tmp->kind = kind;
        tmp->type = type;
        tmp->scope = table->table_count;
	tmp->next = NULL;
	table->entry_count++;
	tmp->attribute = "";
	if(attribute != ""){
            if(table->prev != NULL){
                if(table->prev->tail->attribute == ""){
                    table->prev->tail->attribute = attribute;
	  	}
                else {       	
                    sprintf(get_attr,"%s, %s", table->prev->tail->attribute, attribute);
                    table->prev->tail->attribute = get_attr;
                }
            }
	}
	else{
	    tmp->attribute = "";
	}
        table->tail->next = tmp;
        table->tail = tmp;
    }
}
int lookup_symbol(Table *table, char *name) {
    if (table->entry_count != 0) {
        Ent *find = table->head->next;
        while (find != NULL) {
            if (strcmp(find->name, name) == 0) {
                return 0;
            }
            else {
                find = find->next;
            }
        }
    }
    return 1;
}
void dump_symbol() {
    count_for_table--;
    if (current_table->entry_count != 0) {
	Ent *dump = current_table->head->next;
        printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
        while(dump != NULL) {
            printf("%-10d%-10s%-12s%-10s%-10d%s\n", dump->index, dump->name, dump->kind, dump->type, dump->scope, dump->attribute);
            Ent *free_it = dump;
            dump = dump->next;
            free(free_it);
        }
        printf("\n");
        current_table->entry_count = 0;
    }
    current_table = current_table->prev;
}
