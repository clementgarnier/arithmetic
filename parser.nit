module parser

import pipeline

# Classe d'utilitaires
class Parser
        var input_string: String

        init (s: String) do
                if s.length == 0 then
                        print "Empty input"
                        abort
                end
                self.input_string = s.replace(" ", "")
        end
        
        # Supprime les parenthèses englobant une expression
        private fun remove_englobing do
                # Recherche du pattern (…)
                if input_string.first == '(' and input_string.last == ')' then
                        var trimed = self.input_string.skip_head(1).skip_tail(1).to_s
                        # On vérifie que la dernière parenthèse est correctement fermée
                        if -1 * trimed.last_index_of('(') +  trimed.last_index_of(')') >= 0 then
                                self.input_string = trimed
                                remove_englobing
                        end
                end
        end

        # Parse une expression
        fun parse(top_operator: nullable Operator): Expression do
                self.remove_englobing

                if self.input_string.length == 1 and input_string.first.is_letter then
                        return new UnaryExpression(input_string)
                else
                        return new BinaryExpression(input_string, top_operator)
                end
        end
end

# Abstraction d'expression
interface Expression
        fun format: String is abstract
end

# Expression de la forme operande operateur operande
class BinaryExpression
        super Expression
        
        var left_operand: nullable Expression = null
        var right_operand: nullable Expression = null
        var operator: nullable Operator = null

        # L'opérateur de l'expression du niveau supérieur, s'il y a lieu
        var top_operator: nullable Operator = null

        init (s: String, top_operator: nullable Operator) do
                var open = 0
                var position = 0

                # Recherche d'un opérateur de plus haut niveau
                # (le premier caractère hors parenthèses)
                for c in s do
                        if c == '(' then
                                open = open + 1
                        else if c == ')' then
                                open = open - 1
                        else if not c.is_letter and open == 0 then
                                self.operator = new Operator.from_char(c)
                                break
                        end
                        position = position + 1
                end

                if self.operator == null then
                        print "Expected operator, found nothing in \"{s}\""
                        abort
                end
                
                # Création récursive des sous-expressions
                self.left_operand = (new Parser(s.substring(0, position))).parse(self.operator)
                self.right_operand = (new Parser(s.substring_from(position + 1))).parse(self.operator)
                self.top_operator = top_operator
        end

        redef fun format do
                var text = (left_operand.format.to_a + operator.to_s.to_a + right_operand.format.to_a).to_s
                if self.top_operator != null and
                        (self.top_operator.priority < self.operator.priority or
                        self.top_operator.commutative == false) then
                        return ("(".to_a + text.to_a + ")".to_a).to_s
                else
                        return text
                end
        end
end

# Expression à opérande unique
class UnaryExpression
        super Expression

        var operand: Char
        
        init (s: String) do
                var length = s.length
                if length == 1 then
                        self.operand = s.first
                else
                        print "Invalid operand, expected length 1, found length {length}"
                        abort
                end
        end

        redef fun format do
                return operand.to_s
        end
end

class Operator
        var symbol: Char
        var priority: Int
        var commutative: Bool

        init from_char(s: Char) do
                self.symbol = s
                self.commutative = false
                if s == "^" then
                        self.priority = 1
                else if s == '*' then
                        self.priority = 2
                        self.commutative = true
                else if s == '/' then
                        self.priority = 2
                else if s == '+' then
                        self.priority = 3
                        self.commutative = true
                else if s == '-' then
                        self.priority = 3
                else
                        print "Expected operator, found \"{s}\""
                        abort
                end
        end

        redef fun to_s do
                return (" ".to_a + self.symbol.to_s + " ".to_a).to_s
        end
end

var input_string = args.join("")
var expression: Expression = (new Parser(input_string)).parse(null)

print expression.format

