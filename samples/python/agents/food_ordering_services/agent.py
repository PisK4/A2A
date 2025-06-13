import json
import random
from datetime import datetime, timedelta
from typing import Any, Optional, List, Dict

from google.adk.agents.llm_agent import LlmAgent
from google.adk.artifacts import InMemoryArtifactService
from google.adk.memory.in_memory_memory_service import InMemoryMemoryService
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.tool_context import ToolContext
from task_manager import AgentWithTaskManager


# Local cache of created order_ids for demo purposes.
order_ids = set()

# Sample restaurant database for Bay Area
RESTAURANTS = {
    "pizza": [
        {"name": "Cheese Board Pizza", "location": "Berkeley", "cuisine": "Pizza", "price_range": "$$", "rating": 4.8},
        {"name": "Zachary's Chicago Pizza", "location": "Oakland", "cuisine": "Deep Dish Pizza", "price_range": "$$", "rating": 4.7},
        {"name": "Pizza Hacker", "location": "San Francisco", "cuisine": "Artisan Pizza", "price_range": "$$", "rating": 4.5},
        {"name": "Pizzeria Delfina", "location": "San Francisco", "cuisine": "Italian Pizza", "price_range": "$$$", "rating": 4.6},
        {"name": "A16", "location": "San Francisco", "cuisine": "Neapolitan Pizza", "price_range": "$$$", "rating": 4.4}
    ],
    "chinese": [
        {"name": "China Live", "location": "San Francisco", "cuisine": "Modern Chinese", "price_range": "$$$", "rating": 4.3},
        {"name": "Mister Jiu's", "location": "San Francisco", "cuisine": "Cantonese", "price_range": "$$$", "rating": 4.6},
        {"name": "Yank Sing", "location": "San Francisco", "cuisine": "Dim Sum", "price_range": "$$$", "rating": 4.4},
        {"name": "Great China", "location": "Berkeley", "cuisine": "Northern Chinese", "price_range": "$$", "rating": 4.5},
        {"name": "Chef Zhao Kitchen", "location": "Palo Alto", "cuisine": "Sichuan", "price_range": "$$", "rating": 4.4}
    ],
    "mexican": [
        {"name": "La Taqueria", "location": "San Francisco", "cuisine": "Tacos", "price_range": "$$", "rating": 4.6},
        {"name": "Nopalito", "location": "San Francisco", "cuisine": "Organic Mexican", "price_range": "$$", "rating": 4.5},
        {"name": "Comal", "location": "Berkeley", "cuisine": "Contemporary Mexican", "price_range": "$$$", "rating": 4.4},
        {"name": "Tacos Sinaloa", "location": "Oakland", "cuisine": "Street Tacos", "price_range": "$", "rating": 4.7},
        {"name": "Tacolicious", "location": "Palo Alto", "cuisine": "Modern Mexican", "price_range": "$$", "rating": 4.3}
    ],
    "indian": [
        {"name": "Vik's Chaat", "location": "Berkeley", "cuisine": "Indian Street Food", "price_range": "$", "rating": 4.5},
        {"name": "DOSA", "location": "San Francisco", "cuisine": "South Indian", "price_range": "$$$", "rating": 4.3},
        {"name": "Amber India", "location": "Mountain View", "cuisine": "North Indian", "price_range": "$$$", "rating": 4.4},
        {"name": "Curry Up Now", "location": "San Mateo", "cuisine": "Indian Fusion", "price_range": "$$", "rating": 4.2},
        {"name": "Chapati & Chutney", "location": "Sunnyvale", "cuisine": "Authentic Indian", "price_range": "$$", "rating": 4.6}
    ],
    "japanese": [
        {"name": "Rintaro", "location": "San Francisco", "cuisine": "Izakaya", "price_range": "$$$", "rating": 4.7},
        {"name": "Iyasare", "location": "Berkeley", "cuisine": "Modern Japanese", "price_range": "$$$", "rating": 4.5},
        {"name": "Kiraku", "location": "Berkeley", "cuisine": "Izakaya", "price_range": "$$", "rating": 4.6},
        {"name": "Marufuku Ramen", "location": "San Francisco", "cuisine": "Ramen", "price_range": "$$", "rating": 4.8},
        {"name": "Gintei", "location": "San Mateo", "cuisine": "Sushi", "price_range": "$$$", "rating": 4.4}
    ]
}


def search_restaurants(
    cuisine: Optional[str] = None,
    location: Optional[str] = None,
    price_range: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Search for restaurants based on cuisine, location, and price range.
    
    Args:
        cuisine (str, optional): Type of cuisine (e.g., pizza, chinese, mexican)
        location (str, optional): City or area (e.g., San Francisco, Berkeley)
        price_range (str, optional): Price range as $ symbols (e.g., $, $$, $$$)
        
    Returns:
        List[Dict[str, Any]]: List of matching restaurants
    """
    results = []
    
    # If cuisine is provided, search only in that category
    if cuisine and cuisine.lower() in RESTAURANTS:
        search_categories = [cuisine.lower()]
    else:
        # Otherwise search all categories
        search_categories = RESTAURANTS.keys()
    
    for category in search_categories:
        for restaurant in RESTAURANTS[category]:
            match = True
            
            # Filter by location if provided
            if location and location.lower() not in restaurant["location"].lower():
                match = False
                
            # Filter by price range if provided
            if price_range and price_range != restaurant["price_range"]:
                match = False
                
            if match:
                results.append(restaurant)
    
    # Sort by rating (highest first)
    results.sort(key=lambda x: x["rating"], reverse=True)
    return results


def create_order_form(
    restaurant: Optional[str] = None,
    items: Optional[str] = None,
    delivery_time: Optional[str] = None,
    delivery_address: Optional[str] = None,
    special_instructions: Optional[str] = None,
) -> dict[str, Any]:
    """Create a food order form for the user to fill out.
    
    Args:
        restaurant (str, optional): Restaurant name
        items (str, optional): Food items to order
        delivery_time (str, optional): Requested delivery time (defaults to 30 minutes from now)
        delivery_address (str, optional): Delivery address
        special_instructions (str, optional): Special instructions for the order (defaults to "没有")
        
    Returns:
        dict[str, Any]: A dictionary containing the order form data
    """
    order_id = 'order_' + str(random.randint(1000000, 9999999))
    order_ids.add(order_id)
    
    current_date = datetime.now().strftime("%Y-%m-%d")
    
    # Set default delivery time to 30 minutes from now if not provided
    if not delivery_time:
        now = datetime.now()
        future_time = now + timedelta(minutes=30)
        delivery_time = future_time.strftime("%H:%M")
    
    # Set default special instructions to "none" if not provided
    if special_instructions is None:
        special_instructions = "none"
    
    return {
        'order_id': order_id,
        'restaurant': '<restaurant name>' if not restaurant else restaurant,
        'items': '<food items>' if not items else items,
        'delivery_time': delivery_time,
        'delivery_address': '<delivery address>' if not delivery_address else delivery_address,
        'special_instructions': special_instructions,
        'date': current_date,
    }


def return_order_form(
    form_data: dict[str, Any],
    tool_context: ToolContext,
    instructions: Optional[str] = None,
) -> dict[str, Any]:
    """Returns a structured JSON object for the food order form.
    
    Args:
        form_data (dict[str, Any]): The order form data
        tool_context (ToolContext): The context in which the tool operates
        instructions (str, optional): Instructions for processing the form
        
    Returns:
        dict[str, Any]: A JSON dictionary for the form response
    """
    if isinstance(form_data, str):
        form_data = json.loads(form_data)

    tool_context.actions.skip_summarization = True
    tool_context.actions.escalate = True
    
    form_dict = {
        'type': 'form',
        'form': {
            'type': 'object',
            'properties': {
                'restaurant': {
                    'type': 'string',
                    'description': 'Restaurant name',
                    'title': 'Restaurant',
                },
                'items': {
                    'type': 'string',
                    'description': 'Food items to order',
                    'title': 'Items',
                },
                'delivery_time': {
                    'type': 'string',
                    'description': 'Requested delivery time',
                    'title': 'Delivery Time',
                },
                'delivery_address': {
                    'type': 'string',
                    'description': 'Delivery address',
                    'title': 'Delivery Address',
                },
                'special_instructions': {
                    'type': 'string',
                    'description': 'Special instructions for the order',
                    'title': 'Special Instructions',
                },
                'order_id': {
                    'type': 'string',
                    'description': 'Order ID',
                    'title': 'Order ID',
                },
                'date': {
                    'type': 'string',
                    'format': 'date',
                    'description': 'Date of order',
                    'title': 'Date',
                },
            },
            'required': ['restaurant', 'items', 'delivery_address', 'order_id', 'date'],
        },
        'form_data': form_data,
        'instructions': instructions,
    }
    return json.dumps(form_dict)


def make_reservation(
    restaurant: str,
    date: str,
    time: str,
    party_size: str,
    name: str,
    phone: Optional[str] = None,
    special_requests: Optional[str] = None,
) -> dict[str, Any]:
    """Make a restaurant reservation.
    
    Args:
        restaurant (str): Restaurant name
        date (str): Reservation date
        time (str): Reservation time
        party_size (str): Number of people
        name (str): Customer name
        phone (str, optional): Contact phone number
        special_requests (str, optional): Special requests
        
    Returns:
        dict[str, Any]: Reservation confirmation details
    """
    reservation_id = 'rsv_' + str(random.randint(1000000, 9999999))
    
    # Simulate successful reservation
    return {
        'reservation_id': reservation_id,
        'restaurant': restaurant,
        'date': date,
        'time': time,
        'party_size': party_size,
        'name': name,
        'phone': phone if phone else "Not provided",
        'special_requests': special_requests if special_requests else "None",
        'status': 'confirmed',
    }


def place_order(order_id: str) -> dict[str, Any]:
    """Place a food order with the given order_id.
    
    Args:
        order_id (str): The ID of the order to place
        
    Returns:
        dict[str, Any]: Order status and estimated delivery time
    """
    if order_id not in order_ids:
        return {
            'order_id': order_id,
            'status': 'Error: Invalid order_id.',
        }
    
    # Simulate delivery time (30-60 minutes from now)
    delivery_time = datetime.now()
    delivery_minutes = random.randint(30, 60)
    future_time = delivery_time + timedelta(minutes=delivery_minutes)
    
    # Format time as 12-hour with AM/PM
    formatted_time = future_time.strftime("%I:%M %p")
    
    return {
        'order_id': order_id,
        'status': 'confirmed',
        'estimated_delivery': formatted_time,
        'tracking_url': f"https://fooddelivery.example.com/track/{order_id}",
    }


class FoodOrderingAgent(AgentWithTaskManager):
    """An agent that handles food ordering services for Bay Area customers."""

    SUPPORTED_CONTENT_TYPES = ['text', 'text/plain']

    def __init__(self):
        self._agent = self._build_agent()
        self._user_id = 'remote_agent'
        self._runner = Runner(
            app_name=self._agent.name,
            agent=self._agent,
            artifact_service=InMemoryArtifactService(),
            session_service=InMemorySessionService(),
            memory_service=InMemoryMemoryService(),
        )

    def get_processing_message(self) -> str:
        return '正在处理您的订餐请求...'

    def _build_agent(self) -> LlmAgent:
        """Builds the LLM agent for the food ordering service."""
        return LlmAgent(
            model='gemini-2.0-flash-001',
            name='bay_area_food_ordering_agent_v1',
            description=(
                'This agent helps Bay Area users order food delivery or make restaurant reservations.'
            ),
            instruction="""
你是一个专业的订餐助手，专为北美湾区（旧金山、伯克利、奥克兰、帕洛阿尔托等）的用户提供服务。你可以帮助用户查找餐厅、订购外卖和预订餐厅。

当用户询问餐厅推荐时：
1. 使用search_restaurants()函数来查找符合用户偏好的餐厅
2. 推荐ratings较高的餐厅，并提供其位置、价格范围和特色菜品信息
3. 询问用户是否需要订餐或预订

当用户想要订购外卖时：
1. 使用create_order_form()创建订单表单，只需要提供以下必要信息：
   - 餐厅名称
   - 订购的食物项目
   - 送达地址
2. 送达时间默认为30分钟后，特殊要求默认为"没有"，无需特别询问这些信息
3. 用return_order_form()将表单发送给用户填写
4. 收到用户填写的表单后，检查是否包含所有必要信息
5. 如果信息完整，直接使用place_order()处理订单
6. 在响应中包括订单ID、订单状态和预计送达时间

当用户想要预订餐厅时：
1. 询问并收集以下信息：
   - 餐厅名称
   - 日期
   - 时间
   - 人数
   - 用户姓名
   - 电话号码（可选）
   - 特殊要求（可选）
2. 使用make_reservation()进行预订
3. 在响应中包括预订ID和确认状态

始终保持友好专业的态度，如果用户提出的餐厅或食物在数据库中找不到，请礼貌地告知并推荐类似的选择。

记住你服务的是湾区用户，所以要熟悉该地区的热门餐厅、当地特色菜和用餐习惯。
    """,
            tools=[
                search_restaurants,
                create_order_form,
                return_order_form,
                place_order,
                make_reservation,
            ],
        )
