import logging
import os

import click

from agent import FoodOrderingAgent
from common.server import A2AServer
from common.types import (
    AgentCapabilities,
    AgentCard,
    AgentSkill,
    MissingAPIKeyError,
)
from dotenv import load_dotenv
from task_manager import AgentTaskManager


load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@click.command()
@click.option('--host', default='localhost')
@click.option('--port', default=10002)
@click.option('--verify-signatures', is_flag=True, default=True, help='Enable signature verification')
def main(host, port, verify_signatures):
    try:
        # Check for API key only if Vertex AI is not configured
        if not os.getenv('GOOGLE_GENAI_USE_VERTEXAI') == 'TRUE':
            if not os.getenv('GOOGLE_API_KEY'):
                raise MissingAPIKeyError(
                    'GOOGLE_API_KEY environment variable not set and GOOGLE_GENAI_USE_VERTEXAI is not TRUE.'
                )

        capabilities = AgentCapabilities(streaming=True)
        
        # 定义代理技能
        restaurant_skill = AgentSkill(
            id='restaurant_search',
            name='Restaurant Search Tool',
            description='Helps users find restaurants in the Bay Area based on cuisine, location, and price range.',
            tags=['restaurant', 'search', 'bay area'],
            examples=[
                '我想找湾区的中餐馆',
                '旧金山有什么好的披萨店推荐吗？',
                '伯克利附近有什么价格适中的日本料理？'
            ],
        )
        
        delivery_skill = AgentSkill(
            id='food_delivery',
            name='Food Delivery Tool',
            description='Helps users order food delivery from restaurants in the Bay Area.',
            tags=['delivery', 'food', 'order'],
            examples=[
                '我想点一份披萨外卖',
                '从Zachary\'s Chicago Pizza订餐',
                '我想订购中餐外卖送到家里'
            ],
        )
        
        reservation_skill = AgentSkill(
            id='restaurant_reservation',
            name='Restaurant Reservation Tool',
            description='Helps users make restaurant reservations in the Bay Area.',
            tags=['reservation', 'dining'],
            examples=[
                '我想预订餐厅',
                '今晚在Mister Jiu\'s预订4人的位子',
                '明天晚上7点帮我在Rintaro预约两个人'
            ],
        )
        
        agent_card = AgentCard(
            name='Bay Area Food Ordering',
            description='This agent helps Bay Area users find restaurants, order food delivery, or make restaurant reservations.',
            url=f'http://{host}:{port}/',
            version='1.0.0',
            defaultInputModes=FoodOrderingAgent.SUPPORTED_CONTENT_TYPES,
            defaultOutputModes=FoodOrderingAgent.SUPPORTED_CONTENT_TYPES,
            capabilities=capabilities,
            skills=[restaurant_skill, delivery_skill, reservation_skill],
        )
        
        # Initialize the task manager with signature verification
        logger.info(f"Initializing AgentTaskManager with signature verification: {verify_signatures}")
        task_manager = AgentTaskManager(
            agent=FoodOrderingAgent(),
            verify_signatures=verify_signatures
        )
        
        server = A2AServer(
            agent_card=agent_card,
            task_manager=task_manager,
            host=host,
            port=port,
        )
        server.start()
    except MissingAPIKeyError as e:
        logger.error(f'Error: {e}')
        exit(1)
    except Exception as e:
        logger.error(f'An error occurred during server startup: {e}')
        exit(1)


if __name__ == '__main__':
    main()
